-- OOP quiz seed
-- 16 senaryo tabanlı OOP sorusu: PDF'teki 8 OOP sorusu x 2 varyant.
-- Aynı konunun iki varyantı aynı sort_order değerini paylaşır (ör. oop-001 ve oop-001b).
-- Uygulama, her sort_order grubundan rastgele bir soru seçerek 8 soruluk bir sınav oluşturmalıdır.
-- Hedef quiz: mevcut OOP quiz'i ('oop-001' ya da eski 'solid-oop-003' sorusu üzerinden bulunur); yoksa 'oop' kategorisinde 'OOP' quiz'i oluşturulur.
-- Run explicitly against an existing database; this is not a schema migration.

BEGIN;

INSERT INTO categories (name, slug, description)
SELECT 'OOP', 'oop', 'Nesne yönelimli programlama: temel prensipler, SOLID, tasarım kalıpları ve Java''da uygulanışı'
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id IN ('oop-001', 'solid-oop-003'))
ON CONFLICT (slug) DO NOTHING;

INSERT INTO quizzes (id, title, description, category_id, time_limit_seconds, passing_score)
SELECT '5b2d8c41-7e3a-4f19-b6c2-9a1e4d7f3b62', 'OOP',
       'Senior mülakat: OOP üzerine 8 senaryo.',
       id, 1600, 70
FROM categories
WHERE slug = 'oop'
  AND NOT EXISTS (SELECT 1 FROM questions WHERE id IN ('oop-001', 'solid-oop-003'))
  AND NOT EXISTS (SELECT 1 FROM quizzes WHERE category_id = categories.id AND title = 'OOP');

CREATE TEMP TABLE oop_target ON COMMIT DROP AS
SELECT DISTINCT quiz_id FROM (
    SELECT q.quiz_id::varchar(50) AS quiz_id
    FROM questions q
    WHERE q.id IN ('oop-001', 'solid-oop-003')
    UNION ALL
    SELECT qz.id::varchar(50)
    FROM quizzes qz
    JOIN categories c ON c.id = qz.category_id
    WHERE c.slug = 'oop' AND qz.title = 'OOP'
      AND NOT EXISTS (SELECT 1 FROM questions WHERE id IN ('oop-001', 'solid-oop-003'))
) t;

DO $$
BEGIN
    IF (SELECT count(*) FROM oop_target) <> 1 THEN
        RAISE EXCEPTION 'Expected exactly one OOP quiz';
    END IF;
END;
$$;

UPDATE quizzes
SET title = 'OOP',
    description = 'Senior mülakat: OOP üzerine 8 senaryo.',
    time_limit_seconds = 1600
WHERE id::text = (SELECT quiz_id FROM oop_target);

CREATE TEMP TABLE oop_questions (
    id varchar(50) PRIMARY KEY,
    text text NOT NULL,
    code_snippet text NOT NULL,
    explanation text NOT NULL,
    sort_order integer NOT NULL
) ON COMMIT DROP;

INSERT INTO oop_questions VALUES

-- 1. OOP'nin temel prensipleri ------------------------------------------------

('oop-001',
$q$Bir ödeme modülü üç adımda yeniden düzenleniyor. (1) Payment sınıfının alanları private yapılıyor ve genel setStatus metodu yerine, durum kurallarını kontrol eden approve() ve reject() metotları ekleniyor. (2) Kart, cüzdan ve havale ödemeleri için sağlayıcı ayrıntılarını gizleyen bir PaymentMethod interface'i tanımlanıyor. (3) Checkout kodu tip kontrolü yapmadan paymentMethod.pay(amount) çağırıyor ve her ödeme türü kendi pay implementasyonunu çalıştırıyor. Bu adımlar sırasıyla hangi OOP prensiplerine karşılık gelir?$q$,
'',
$e$Birinci adım encapsulation'dır: nesne kendi state'ini korur ve durum değişikliği sadece kuralları uygulayan metotlarla yapılır. İkinci adım abstraction'dır: PaymentMethod, ödemenin nasıl yapıldığını gizleyip ne yapıldığını tanımlayan bir sözleşme sunar. Üçüncü adım polymorphism'dir: aynı pay çağrısı, runtime'da nesnenin gerçek tipine göre farklı implementasyonları çalıştırır. Bir interface'i implement etmek alt tür ilişkisi kurar, ama klasik anlamda state veya implementasyon kalıtımı değildir; üçüncü adımdaki esas kavram runtime polymorphism'dir. Encapsulation ile abstraction sık karıştırılır: encapsulation nesnenin iç state'ini ve kurallarını korumakla, abstraction ise dışarıya sunulan sözleşmenin implementasyon ayrıntılarından bağımsız olmasıyla ilgilidir.$e$, 1),

('oop-001b',
$q$Bir bildirim modülünde aşağıdaki sınıf yazılmış; e-posta ve SMS bildirimleri bu sınıftan türüyor ve kendi render ile deliver metotlarını yazıyor. Kod incelemesinde dört farklı yorum yapılıyor. Hangi yorum OOP prensiplerini doğru ilişkilendiriyor?$q$,
$code$public abstract class Notification {
    private final String recipient;

    protected Notification(String recipient) {
        if (recipient == null || recipient.isBlank()) {
            throw new IllegalArgumentException("recipient is required");
        }
        this.recipient = recipient;
    }

    public final void send() {
        deliver(recipient, render());
    }

    protected abstract String render();
    protected abstract void deliver(String to, String body);
}

// istemci kod
pending.forEach(Notification::send);$code$,
$e$recipient alanının private final olması ve geçerliliğinin constructor'da kontrol edilmesi encapsulation'dır: nesne, kendi state'inin hiçbir zaman geçersiz olmamasını kendisi garanti eder. İstemci yalnızca send çağırır; hangi alt sınıfın render ve deliver metotlarının çalışacağı runtime'da nesnenin gerçek tipine göre belirlenir, bu da polymorphism'dir. Bir alanın private olması abstraction değil encapsulation'dır; abstraction, istemciye ayrıntılardan bağımsız bir sözleşme (burada send) sunmakla ilgilidir ve abstract anahtar kelimesinin kullanılması tek başına bunu kanıtlamaz. send metodunun final olması polymorphism'i engellemez: akış sabittir, değişen adımlar alt sınıfların override ettiği metotlardır (Template Method). Overload ise derleme zamanında seçilir; buradaki dinamik seçim overriding sayesinde yapılır. Alt sınıfların bu sınıftan türemesi inheritance'tır, ama bu inheritance polymorphism'in aracıdır, alternatifi değil.$e$, 1),

-- 2. Design pattern'lar --------------------------------------------------------

('oop-002',
$q$Bir e-ticaret uygulamasında indirim hesabı, müşteri tipine göre büyüyen bir if/else zinciriyle yapılıyor. Her yeni müşteri tipi bu metodun değiştirilmesini ve tüm indirim testlerinin yeniden çalıştırılmasını gerektiriyor. Ayrıca bazı kampanyalarda hangi hesaplamanın kullanılacağının runtime'da konfigürasyondan seçilmesi isteniyor. En uygun tasarım hangisidir?$q$,
$code$BigDecimal discount(Order order, CustomerType type) {
    if (type == CustomerType.REGULAR) {
        return BigDecimal.ZERO;
    } else if (type == CustomerType.GOLD) {
        return order.total().multiply(new BigDecimal("0.10"));
    } else if (type == CustomerType.CORPORATE) {
        return corporateDiscount(order);
    }
    throw new IllegalArgumentException("Unknown type: " + type);
}$code$,
$e$Strategy, aynı işin farklı yollarla yapılabildiği durumlarda her algoritmayı ayrı bir sınıfa koyar. Her indirim kuralı bir DiscountStrategy implementasyonu olur ve yeni bir indirim kuralı, hesaplama kodunu değiştirmeden yeni bir strategy sınıfıyla eklenir; yalnızca registry veya wiring konfigürasyonu genişler. Hangi stratejinin kullanılacağına karar verme işi ise istemciden ayrılıp bir factory veya registry'ye verilir; Spring'de tüm implementasyonlar bir Map<CustomerType, DiscountStrategy> olarak enjekte edilip key'e göre seçilebilir. Template Method, sabit bir akışın bazı adımları değiştiğinde uygundur; burada değişen hesaplamanın tamamıdır ve seçim runtime'da yapılmalıdır. Her strateji için Singleton yazmak nesne oluşturmayı tekilleştirir ama seçim sorununu çözmez; if/else bu kez getInstance çağrılarıyla devam eder. Observer bir olayı birden çok dinleyiciye iletmek içindir, tek bir hesaplamayı seçmek için değil.$e$, 2),

('oop-002b',
$q$Bir uygulamada döviz kurları, aşağıdaki klasik Singleton ile servislerin içinden okunuyor. Unit testlerde gerçek kur sağlayıcısına gidilmesi istenmiyor, ama ExchangeRates servislerin içinde doğrudan getInstance() ile alındığı için sahte bir implementasyon verilemiyor. Ayrıca bir testte değiştirilen kurlar diğer testleri de etkiliyor. Ekipten biri Singleton'ı enum ile yazmayı öneriyor. En doğru değerlendirme hangisidir?$q$,
$code$public class ExchangeRates {
    private static final ExchangeRates INSTANCE = new ExchangeRates();
    private final Map<String, BigDecimal> rates = new ConcurrentHashMap<>();

    private ExchangeRates() { loadFromProvider(); }

    public static ExchangeRates getInstance() { return INSTANCE; }

    public BigDecimal rate(String currency) { return rates.get(currency); }
}

// PricingService içinde:
BigDecimal rate = ExchangeRates.getInstance().rate("USD");$code$,
$e$Singleton tek instance ve ona global erişim sağlar; bu global erişim aynı zamanda bağımlılığı gizler ve state'i tüm testler arasında paylaştırır. Enum Singleton, reflection ve serialization ile ikinci bir instance oluşturulmasını engeller, ama ne bağımlılığı görünür yapar ne de paylaşılan state'i ortadan kaldırır. Doğru yaklaşım, kur bilgisini bir interface (ör. RateProvider) arkasına almak ve servislere constructor ile vermektir. Uygulamada tek instance gerekiyorsa bunu DI container'ın singleton scope'u sağlar; testlerde ise sahte bir implementasyon doğrudan verilir. getInstance'ı synchronized yapmak thread-safety ile ilgilidir ve test edilebilirliği değiştirmez. Static final bir alanı reflection ile değiştirmek kırılgandır ve modern JVM'lerde çalışmayabilir.$e$, 2),

-- 3. SOLID ---------------------------------------------------------------------

('oop-003',
$q$Bir bankacılık uygulamasında vadeli mevduat hesapları için Account'tan türeyen FixedDepositAccount sınıfı yazıldı. Vade dolmadan para çekilemediği için withdraw metodu UnsupportedOperationException fırlatıyor. Ay sonu işlemi, tüm hesaplardan hesap işletim ücretini çekerken FixedDepositAccount'a geldiğinde çöküyor. Ekip bu hatayı, ay sonu işlemine bir instanceof kontrolü ekleyerek çözmeyi düşünüyor. En doğru değerlendirme hangisidir?$q$,
$code$public class Account {
    protected BigDecimal balance;

    public void withdraw(BigDecimal amount) {
        balance = balance.subtract(amount);
    }
}

public class FixedDepositAccount extends Account {
    @Override
    public void withdraw(BigDecimal amount) {
        throw new UnsupportedOperationException("Vade dolmadan çekim yapılamaz");
    }
}

// Ay sonu işlemi
for (Account account : accounts) {
    account.withdraw(MONTHLY_FEE);
}$code$,
$e$Liskov Substitution'a göre bir alt sınıf, üst sınıfın kullanıldığı her yerde programın davranışını bozmadan onun yerine geçebilmelidir. FixedDepositAccount bunu yapamıyor: Account kullanan kod her hesabın withdraw'u desteklediğini varsayabilir. Bu, uçamayan bir Penguin'in Bird'ün fly() metodunu exception ile ezmesiyle aynı durumdur. instanceof kontrolü sorunu çözmez, sadece gizler: Account kullanan her yeni kod aynı kontrolü yapmak zorunda kalır ve yeni bir alt tip eklendiğinde bu kontroller güncellenmelidir; bu da Open/Closed prensibini bozar. Doğru çözüm hiyerarşiyi yeteneklere göre ayırmaktır: para çekilebilen hesaplar ayrı bir interface (ör. Withdrawable) uygular ve ücret kesen kod sadece bu tipteki hesaplarla çalışır. Sessizce hiçbir şey yapmayan bir withdraw da LSP'yi bozar, çünkü çağıran taraf çekimin gerçekleştiğini varsayar. Sorun sınıfın sorumluluk sayısıyla (SRP) değil, alt tipin üst tipin yerine geçememesiyle ilgilidir.$e$, 3),

('oop-003b',
$q$Bir sipariş servisi, sipariş kaydını MySQL'e yazıp müşteriye e-posta gönderiyor. Ekip, servisi gerçek veritabanı ve SMTP sunucusu olmadan test etmek, ileride de e-posta yerine SMS göndermek istiyor. Bir geliştirici MySqlOrderRepository ve SmtpEmailSender için birer interface oluşturup alan tiplerini bu interface'lerle değiştiriyor; servisin son hali aşağıda. Bu değişiklikle ilgili en doğru değerlendirme hangisidir?$q$,
$code$public class OrderService {
    private final OrderRepository repository = new MySqlOrderRepository();
    private final EmailSender emailSender = new SmtpEmailSender();

    public void placeOrder(Order order) {
        repository.save(order);
        emailSender.send(order.customerEmail(), "Siparişiniz alındı");
    }
}$code$,
$e$Dependency Inversion'a göre üst seviye modüller alt seviye detaylara değil soyutlamalara bağlı olmalıdır. Alanların interface tipinde olması tek başına bunu sağlamaz: servis somut sınıfları hâlâ kendisi new ile oluşturduğu için onlara bağımlı kalır, testte sahte bir implementasyon verilemez ve SMS'e geçmek yine bu sınıfı değiştirmeyi gerektirir. Doğrusu, servisin ihtiyacını ifade eden soyutlamaları (ör. OrderRepository, OrderNotifier) tanımlamak ve implementasyonları dışarıdan, tercihen constructor ile vermektir. Hangi implementasyonun kullanılacağına uygulamanın kurulduğu yer (Spring'de container) karar verir. Soyutlamanın adı da implementasyondan değil ihtiyaçtan gelmelidir: EmailSender yerine OrderNotifier, SMS'e geçişi doğal kılar. Statik yardımcı metotlar bağımlılığı daha da gizler ve test edilebilirliği azaltır. Servisi SmtpEmailSender'dan türetmek ise bağımlılığı kalıtım yoluyla daha sıkı hale getirir.$e$, 3),

-- 4. Interface ve abstract class -----------------------------------------------

('oop-004',
$q$Bir raporlama modülünde CSV, Excel ve PDF dışa aktarma sınıfları var. Üçünde de akış aynı: dosyayı aç, başlığı yaz, satırları yaz, yazılan satır sayısını alt bilgiye ekle, dosyayı kapat. Sadece başlığın ve satırların biçimlendirilmesi formata göre değişiyor. Ortak akış ve satır sayacı şu an her sınıfta tekrar ediyor. İstemci kod ise sadece export(data) çağırıyor. En uygun tasarım hangisidir?$q$,
'',
$e$İstemcinin bağlandığı sözleşme ayrı tutulur: Exporter interface'i sadece export(data) metodunu tanımlar. Ortak akış ve state (açık dosya, yazılan satır sayısı) ise bir abstract base class'ta toplanır; export metodu sabit akışı yürütür, formata göre değişen başlık ve satır yazma adımları abstract bırakılır. Abstract class bu iş için uygundur, çünkü hem somut metot hem de instance state ve constructor taşıyabilir. Interface'lerdeki alanlar her zaman public static final'dır; bu yüzden nesne başına bir sayaç tutamaz. Her format için ayrı interface tanımlamak istemciyi formatlara bağımlı yapar. Tamamen bağımsız sınıflar ise tekrar eden akışı ve sayacı korur. Burada abstract class sadece kod tekrarı için değil, gerçekten ortak state ve akışı paylaşan bir hiyerarşi için kullanılıyor; istemcinin interface'e bağlanması da ileride bu akışı kullanmayan bir implementasyonun eklenebilmesini sağlar.$e$, 4),

('oop-004b',
$q$Bir ödeme uygulamasında PaymentService, kullanılan framework'ün BaseService sınıfından türüyor. Ekip, bu servise hem denetim (audit) kaydı hem de metrik toplama yeteneği eklemek istiyor. Bir geliştirici bu iki yetenek için AuditableService ve MeasurableService adında iki abstract class yazıyor ve PaymentService'in ikisinden de türemesini planlıyor. Bu planla ilgili en doğru değerlendirme hangisidir?$q$,
'',
$e$Java'da bir sınıf yalnızca tek bir sınıftan türeyebilir, ama birden fazla interface uygulayabilir. PaymentService zaten BaseService'ten türediği için başka bir abstract class'tan türeyemez. Abstract class'ların somut olmaması bu kuralı değiştirmez. Interface'ler ise instance alanı tutamaz; içlerindeki alanlar her zaman static final sabitlerdir, bu yüzden logger veya sayaç gibi state gerektiren ortak kod default metotlarla paylaşılamaz. Yetenekler interface olarak tanımlanmalıdır; bir sınıf ihtiyaç duyduğu kadar yetenek interface'i uygulayabilir. Ortak audit veya metrik kodu ise composition ile, örneğin enjekte edilen bir AuditRecorder ya da MetricsRecorder nesnesiyle paylaşılır; durum tutmayan basit davranışlar için interface'teki default metotlar da kullanılabilir. Abstract class'ları bir zincir halinde birbirinden türetmek derlenir ama her servisi iki yeteneği birden almaya zorlar ve hiyerarşiyi sıkı biçimde birbirine bağlar. Abstract class sadece kod tekrarını azaltmak için değil, gerçek ve ortak bir state veya akış varsa tercih edilmelidir.$e$, 4),

-- 5. Abstraction ve polymorphism -----------------------------------------------

('oop-005',
$q$Bir geometri kütüphanesinde Shape interface'i area() metodunu tanımlıyor ve Circle, Rectangle, Triangle bu interface'i uyguluyor. Ancak toplam alanı hesaplayan istemci kod aşağıdaki gibi yazılmış. Yeni bir Hexagon tipi eklendiğinde toplam alanın yanlış hesaplandığı ve bu metodun da güncellenmesi gerektiği fark ediliyor. Bu kodla ilgili en doğru değerlendirme hangisidir?$q$,
$code$double totalArea(List<Shape> shapes) {
    double total = 0;
    for (Shape s : shapes) {
        if (s instanceof Circle c) {
            total += Math.PI * c.radius() * c.radius();
        } else if (s instanceof Rectangle r) {
            total += r.width() * r.height();
        } else if (s instanceof Triangle t) {
            total += 0.5 * t.base() * t.height();
        }
    }
    return total;
}$code$,
$e$Shape interface'i bir soyutlama sunuyor: her şeklin bir alanı olduğunu söylüyor ve nasıl hesaplandığını gizliyor. Abstraction "ne" sorusunu, polymorphism ise aynı "ne" için farklı "nasıl" implementasyonlarının çalışmasını sağlar. İstemci kod bu soyutlamayı kullanmak yerine somut tipleri tek tek kontrol edip hesaplamayı kendisi yapıyor; böylece polymorphism'den yararlanmıyor. s.area() çağrıldığında runtime'da nesnenin gerçek tipinin implementasyonu çalışır ve yeni bir şekil eklemek istemci kodu değiştirmeyi gerektirmez. Bu kodda Hexagon hiçbir dala girmediği için sessizce toplama eklenmiyor. Interface'ler polymorphism için yeterlidir; abstract class gerekmez. Sanal metot çağrısı JIT tarafından iyi optimize edilir, performans tip kontrolü için bir gerekçe değildir.$e$, 5),

('oop-005b',
$q$Bir ödeme modülünde PaymentProcessor interface'i ve onu uygulayan CardPaymentProcessor ile WalletPaymentProcessor sınıfları var. Checkout servisi aşağıdaki gibi yazılmış ve işlemciyi constructor'dan alıyor. Ekip, bazı müşteriler için cüzdan ödemesini kullanmak istediğinde bunun checkout servisini değiştirmeden mümkün olmadığını fark ediyor. Sorunun temel nedeni nedir?$q$,
$code$public interface PaymentProcessor {
    PaymentResult pay(Order order);
}

public class CheckoutService {
    private final CardPaymentProcessor processor;

    public CheckoutService(CardPaymentProcessor processor) {
        this.processor = processor;
    }

    public PaymentResult checkout(Order order) {
        return processor.pay(order);
    }
}$code$,
$e$Soyutlama (PaymentProcessor) tanımlanmış, ama istemci ona değil somut CardPaymentProcessor tipine bağlanmış. Polymorphism'den yararlanabilmek için istemcinin soyut tipe referans vermesi gerekir: alan ve constructor parametresi PaymentProcessor olursa, hangi implementasyon verilirse pay çağrısı runtime'da o nesnenin metodunu çalıştırır ve checkout servisi değişmez. İşlemciyi türe göre servisin içinde oluşturmak sorunu yalnızca taşır: servis yine tüm somut sınıfları bilir ve her yeni ödeme türünde değişmek zorunda kalır. WalletPaymentProcessor'ı CardPaymentProcessor'dan türetmek derlenir, ama cüzdan bir kart işlemcisi değildir: kart davranışını devralır ve yanlış bir is-a ilişkisi kurar. Overload'lar ise derleme zamanında argümanın statik tipine göre seçilir, runtime'daki ödeme türüne göre değil.$e$, 5),

-- 6. Inheritance ve composition ------------------------------------------------

('oop-006',
$q$Bir ekip, bir kümeye kaç eleman eklenmeye çalışıldığını ölçmek için HashSet'ten türeyen aşağıdaki sınıfı yazdı. Kod çalıştırıldığında konsola ne yazdırılır?$q$,
$code$public class CountingSet<E> extends HashSet<E> {
    private int addCount = 0;

    @Override
    public boolean add(E e) {
        addCount++;
        return super.add(e);
    }

    @Override
    public boolean addAll(Collection<? extends E> c) {
        addCount += c.size();
        return super.addAll(c);
    }

    public int getAddCount() {
        return addCount;
    }
}

CountingSet<String> set = new CountingSet<>();
set.addAll(List.of("a", "b", "c"));
System.out.println(set.getAddCount());$code$,
$e$HashSet'in addAll implementasyonu (AbstractCollection'dan gelir) her eleman için add metodunu çağırır. add override edildiği için bu çağrılar CountingSet'teki add'e gider ve her eleman bir kez daha sayılır: addAll içinde 3, add üzerinden 3 daha, toplam 6. Sorun, alt sınıfın doğru çalışmasının üst sınıfın iç implementasyon ayrıntısına bağlı olmasıdır; üst sınıfın implementasyonu değişirse alt sınıfın davranışı da değişir. Kalıtımın yarattığı güçlü coupling budur. Composition ile çözüm: CountingSet bir Set'i içinde tutar, Set interface'ini uygular ve çağrıları bu nesneye iletir. Böylece içteki nesnenin addAll'u kendi add'ini çağırsa bile sayaç etkilenmez.$e$, 6),

('oop-006b',
$q$Bir denetim (audit) modülünde kayıtların sadece eklenebilmesi, hiçbir zaman silinmemesi veya değiştirilmemesi gerekiyor. Bir geliştirici, liste metotlarını yeniden yazmamak için aşağıdaki sınıfı ArrayList'ten türetti ve silme işlemlerini engellemek için remove, set ve clear metotlarını UnsupportedOperationException fırlatacak şekilde override etti. Kod incelemesinde bu tasarım reddediliyor. En doğru gerekçe hangisidir?$q$,
$code$public class AuditLog extends ArrayList<AuditEntry> {

    @Override
    public AuditEntry remove(int index) {
        throw new UnsupportedOperationException();
    }

    @Override
    public AuditEntry set(int index, AuditEntry entry) {
        throw new UnsupportedOperationException();
    }

    @Override
    public void clear() {
        throw new UnsupportedOperationException();
    }
}$code$,
$e$Bir denetim kaydı bir liste değildir, bir listeye sahiptir; ilişki is-a değil has-a'dır. Kalıtım üst sınıfın tüm public API'sini alt sınıfa taşır. ArrayList'te kaydı silen veya değiştiren başka yollar da vardır: removeIf, removeAll, retainAll, replaceAll, subList(...).clear() ve iterator().remove(). Bunların bir kısmı override edilen metotları hiç çağırmadan iç diziyi doğrudan değiştirir; üst sınıfa ileride eklenecek metotlar da korumanın dışında kalır. Composition ile çözüm: AuditLog içinde private bir liste tutar, dışarıya sadece ekleme metodu ve değiştirilemez bir okuma görünümü sunar. Böylece "sadece eklenebilir" kuralı tek bir yerde korunur. Sınıfı final yapmak alt sınıfları engeller ama ArrayList'ten gelen metotları engellemez. Exception yerine false veya null döndürmek ise çağıranı, işlemin yapıldığını sandırarak yanıltır.$e$, 6),

-- 7. Overloading ve overriding -------------------------------------------------

('oop-007',
$q$Aşağıdaki kod çalıştırıldığında konsola ne yazdırılır?$q$,
$code$class Notifier {
    void send(Object message) {
        System.out.println("Notifier-object");
    }

    void send(String message) {
        System.out.println("Notifier-string");
    }
}

class SmsNotifier extends Notifier {
    @Override
    void send(Object message) {
        System.out.println("Sms-object");
    }
}

Notifier notifier = new SmsNotifier();
Object message = "hello";

notifier.send(message);
notifier.send("hello");$code$,
$e$Java bu kararı iki aşamada verir. Hangi overload'un çağrılacağı derleme zamanında, argümanın statik tipine göre seçilir: message değişkeninin statik tipi Object olduğu için ilk çağrıda send(Object), ikinci çağrıda String literal verildiği için send(String) seçilir. Seçilen metodun hangi implementasyonunun çalışacağı ise runtime'da, nesnenin gerçek tipine göre belirlenir. SmsNotifier send(Object)'i override ettiği için ilk çağrı Sms-object yazar. send(String) override edilmediği için ikinci çağrı Notifier'daki implementasyonu çalıştırır ve Notifier-string yazar. Argümanın runtime'daki tipinin String olması overload seçimini değiştirmez.$e$, 7),

('oop-007b',
$q$Aşağıdaki kod çalıştırıldığında konsola ne yazdırılır?$q$,
$code$class Parent {
    static String type() { return "parent"; }

    String name() { return "parent"; }
}

class Child extends Parent {
    static String type() { return "child"; }

    @Override
    String name() { return "child"; }
}

Parent p = new Child();
System.out.println(p.type() + " " + p.name());$code$,
$e$Static metotlar override edilmez, gizlenir (method hiding). p.type() çağrısında hangi metodun çalışacağı nesneye değil, p değişkeninin statik tipi olan Parent'a göre derleme zamanında belirlenir; sonuç parent olur. Static bir metodu instance üzerinden çağırmak derlenir, ancak derleyici uyarı verebilir; doğru kullanım Parent.type() şeklindedir. name() bir instance metodudur ve override edilmiştir; runtime'da nesnenin gerçek tipine göre Child'daki implementasyon çalışır. Static metodun üzerine @Override eklemek derleme hatası verirdi. Benzer şekilde private metotlar alt sınıfta görünmediği için override edilmez, final metotlar ise override edilemez.$e$, 7),

-- 8. Encapsulation -------------------------------------------------------------

('oop-008',
$q$Bir üyelik sisteminde User sınıfı aşağıdaki gibi tanımlanmış. Kurallara göre engellenmiş (BLOCKED) bir kullanıcı tekrar aktif edilemiyor. Ancak bir yönetim aracının setStatus("ACTIVE") çağırması yüzünden engellenmiş kullanıcıların sisteme tekrar girebildiği görülüyor; veritabanında "ACTVE" gibi hatalı durum değerleri de var. En doğru düzeltme hangisidir?$q$,
$code$public class User {
    private String status;

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }
}$code$,
$e$Alanın private olması tek başına encapsulation sağlamaz; genel setter herkesin nesneyi geçersiz bir duruma sokmasına izin verir. Burada iki ayrı sorun var: geçersiz değer (ACTVE) ve geçersiz geçiş (BLOCKED'dan ACTIVE'e). Enum ilk sorunu çözer ama setter kaldığı sürece ikincisini çözmez; setter içinde izin verilen değerleri doğrulamak da yalnızca ilk sorunu çözer. Doğru çözüm, durum değişikliğini nesnenin kendi davranışlarına bırakmaktır: activate() BLOCKED kontrolü yapar, block() ve deactivate() kendi kurallarını uygular. Böylece nesne durum geçişini, validasyonu ve iş kuralını kendisi kontrol eder. Kuralı controller'da tutmak, User'ı kullanan her yeni kodun aynı kontrolü tekrar etmesini gerektirir ve bir yerde unutulabilir.$e$, 8),

('oop-008b',
$q$Bir cüzdan uygulamasında bakiye kontrolü ve düşümü, Wallet nesnesini kullanan beş farklı serviste aşağıdaki kalıpla yapılıyor. Yeni eklenen bir servis bakiye kontrolünü unuttuğu için bazı cüzdanların bakiyesi eksiye düşüyor. Bu sorunu kalıcı olarak önlemek için en doğru tasarım değişikliği hangisidir?$q$,
$code$// Servislerde tekrar eden kalıp
if (wallet.getBalance().compareTo(amount) >= 0) {
    wallet.setBalance(wallet.getBalance().subtract(amount));
} else {
    throw new InsufficientBalanceException();
}$code$,
$e$Kural, verinin sahibi olan nesnenin içinde değil, onu kullanan servislerde duruyor. Wallet sadece veri taşıyan bir nesneye dönüşmüş ve genel setBalance metodu herkesin kuralı atlamasına izin veriyor. Kalıcı çözüm, kuralı Wallet'ın içine almaktır: withdraw(amount) metodu kontrolü yapar ve bakiyeyi düşürür, setBalance kaldırılır. Böylece kural tek bir yerde durur ve domain API'si üzerinden hiçbir servis onu atlayamaz. Ancak aynı cüzdanı eşzamanlı güncelleyen iki transaction ayrı bir concurrency problemidir; bunun için optimistic/pessimistic locking, atomic SQL update veya DB constraint gibi persistence seviyesinde mekanizmalar da gerekir. Ortak bir validator sınıfı tekrarı azaltır, ama çağrılmasını zorunlu kılmaz; yeni bir servis onu da unutabilir. Veritabanındaki bir CHECK constraint iyi bir ek savunma katmanıdır, ama hatayı ancak kayıt anında ve teknik bir hata olarak yakalar; domain kuralının yerini tutmaz. volatile sadece thread'ler arası görünürlükle ilgilidir ve unutulan bir kontrolü telafi etmez.$e$, 8);

CREATE TEMP TABLE oop_options (
    question_id varchar(50) NOT NULL REFERENCES oop_questions(id),
    text text NOT NULL,
    is_correct boolean NOT NULL,
    sort_order integer NOT NULL,
    PRIMARY KEY (question_id, sort_order)
) ON COMMIT DROP;

INSERT INTO oop_options VALUES

('oop-001', $o$Abstraction, encapsulation, inheritance$o$, false, 0),
('oop-001', $o$Encapsulation, inheritance, polymorphism$o$, false, 1),
('oop-001', $o$Encapsulation, abstraction, polymorphism$o$, true, 2),
('oop-001', $o$Abstraction, polymorphism, encapsulation$o$, false, 3),

('oop-001b', $o$recipient'ın private final tutulup constructor'da doğrulanması encapsulation, her bildirimin kendi metotlarını çalıştırması polymorphism'dir.$o$, true, 0),
('oop-001b', $o$Sınıf abstract tanımlandığı için abstraction sağlanmıştır; recipient'ın private olması da alanı dışarıdan gizlediği için abstraction'ın bir parçasıdır.$o$, false, 1),
('oop-001b', $o$send metodu final olduğu için alt sınıflar onu override edemez; bu yüzden burada polymorphism yoktur, tüm bildirimler aynı send davranışını çalıştırır.$o$, false, 2),
('oop-001b', $o$Alt sınıfların render ve deliver'ı yazması polymorphism değil inheritance'tır; polymorphism için her bildirim türüne ayrı send overload'u gerekir.$o$, false, 3),

('oop-002', $o$Her müşteri tipi için Order'dan türeyen bir alt sınıf yazmak ve indirim adımlarını Template Method ile base class'taki sabit akışa bağlamak.$o$, false, 0),
('oop-002', $o$Her indirim kuralını bir DiscountStrategy implementasyonuna taşımak, kullanılacak stratejiyi bir registry veya factory ile seçmek.$o$, true, 1),
('oop-002', $o$Her indirim kuralını ayrı bir Singleton sınıfa taşımak ve if/else zincirinde bu sınıfların getInstance metotlarını çağırarak hesaplamayı yapmak.$o$, false, 2),
('oop-002', $o$İndirim hesaplayıcılarını Observer olarak kaydetmek ve sipariş oluşunca hepsine haber verip uygun olanın indirimi uygulamasını beklemek.$o$, false, 3),

('oop-002b', $o$Enum Singleton doğru çözümdür; reflection ve serialization'a karşı güvenli olduğu için testlerin birbirini etkilemesi de kendiliğinden önlenir.$o$, false, 0),
('oop-002b', $o$getInstance metodu synchronized yapılmalıdır; testler paralel çalıştığı için aynı instance'a eşzamanlı erişim testleri birbirine bağlar.$o$, false, 1),
('oop-002b', $o$Testlerde INSTANCE alanı reflection ile sahte bir nesneyle değiştirilmeli, her testten sonra da orijinal instance'a geri dönülmelidir.$o$, false, 2),
('oop-002b', $o$Enum bu sorunu çözmez; kur bilgisi bir interface arkasına alınıp constructor ile verilmeli, tekil ömür DI container'a bırakılmalıdır.$o$, true, 3),

('oop-003', $o$Bu bir LSP ihlalidir; instanceof sorunu sadece gizler. Çekim yapılabilen hesaplar ayrı bir yetenek interface'i ile ayrılmalıdır.$o$, true, 0),
('oop-003', $o$Bu bir LSP ihlali değildir, çünkü metot imzası aynıdır; instanceof kontrolü Open/Closed'a da uygun olduğu için kalıcı bir çözümdür.$o$, false, 1),
('oop-003', $o$Bu bir SRP ihlalidir; FixedDepositAccount hem hesap hem vade sorumluluğu taşıdığı için vade kuralları ayrı bir servise taşınmalıdır.$o$, false, 2),
('oop-003', $o$Exception yerine withdraw metodunu boş bırakmak yeterlidir; bu durumda alt sınıf, üst sınıfın yerine sorunsuz geçebilir ve LSP korunur.$o$, false, 3),

('oop-003b', $o$Değişiklik yeterlidir; alanlar artık interface tipinde olduğu için servis somut sınıflara değil soyutlamalara bağlıdır ve DIP sağlanmıştır.$o$, false, 0),
('oop-003b', $o$Değişiklik gereksizdir; repository ve gönderici statik yardımcı metotlara dönüştürülürse servis bağımlılık taşımadan test edilebilir.$o$, false, 1),
('oop-003b', $o$Değişiklik yetmez; nesneler hâlâ servisin içinde oluşturuluyor. Servisin ihtiyacını ifade eden soyutlamalar constructor ile verilmeli.$o$, true, 2),
('oop-003b', $o$Değişiklik yetmez; OrderService, SmtpEmailSender'dan türetilirse e-posta davranışı override edilerek testte ve SMS geçişinde değiştirilebilir.$o$, false, 3),

('oop-004', $o$Exporter bir interface olmalı; ortak akış bir default metotta, satır sayacı da interface'te tanımlanan bir alanda tutulmalıdır.$o$, false, 0),
('oop-004', $o$Her format kendi interface'ini tanımlamalı; istemci CsvExporter veya PdfExporter gibi interface'lere bağlanıp formatı kendisi seçmelidir.$o$, false, 1),
('oop-004', $o$Üç format tamamen bağımsız sınıflar olarak kalmalıdır; tekrar eden ortak kodun maliyeti, kalıtımın getireceği coupling'den daha azdır.$o$, false, 2),
('oop-004', $o$İstemci bir Exporter interface'ine bağlanmalı; ortak akış ve sayaç abstract bir base class'ta, değişen adımlar alt sınıflarda olmalıdır.$o$, true, 3),

('oop-004b', $o$Yetenekler interface olmalı; audit ve metrik kodu, logger ve sayaç alanlarıyla birlikte interface'lerde default metot olarak yazılabilir.$o$, false, 0),
('oop-004b', $o$Java'da bir sınıf yalnız tek sınıftan türeyebilir; yetenekler interface olmalı, ortak kod composition ile paylaşılmalı.$o$, true, 1),
('oop-004b', $o$Plan zincirle uygulanabilir; abstract class'lar birbirinden türetilirse her servis istediği yeteneği bağımsız olarak seçebilir.$o$, false, 2),
('oop-004b', $o$Interface kullanılamaz; interface'ler yalnızca abstract metot içerebildiği için ortak audit kodu hiçbir şekilde paylaşılamaz.$o$, false, 3),

('oop-005', $o$Kod doğrudur; instanceof pattern matching sanal metot çağrısından hızlı olduğu için yoğun hesaplamalarda bu yaklaşım tercih edilmelidir.$o$, false, 0),
('oop-005', $o$İstemci soyutlamayı atlayıp tipleri kendisi kontrol ediyor; toplam s.area() ile alınırsa her şekil kendi alanını hesaplar, kod değişmez.$o$, true, 1),
('oop-005', $o$Shape bir interface olduğu için polymorphism çalışmaz; area metodunun runtime'da doğru şekle bağlanması için Shape abstract class olmalıdır.$o$, false, 2),
('oop-005', $o$Sorun yalnızca Hexagon dalının unutulmasıdır; her yeni şekil için bu metoda yeni bir else if eklemek abstraction'a da uygundur.$o$, false, 3),

('oop-005b', $o$Servise ödeme türünü alan bir factory metodu eklenmeli; işlemciyi türe göre kendisi oluşturursa constructor'a dokunmadan cüzdan da desteklenir.$o$, false, 0),
('oop-005b', $o$WalletPaymentProcessor, CardPaymentProcessor'dan türetilmelidir; böylece mevcut constructor'a cüzdan işlemcisi de verilebilir.$o$, false, 1),
('oop-005b', $o$pay metodu her ödeme türü için ayrı overload'larla tanımlanmalıdır; hangi overload'un çalışacağı runtime'da ödeme türüne göre seçilir.$o$, false, 2),
('oop-005b', $o$Servis soyutlamaya değil somut tipe bağlı; alan ve constructor PaymentProcessor tipinde olursa pay çağrısı polimorfik çalışır.$o$, true, 3),

('oop-006', $o$3$o$, false, 0),
('oop-006', $o$0$o$, false, 1),
('oop-006', $o$6$o$, true, 2),
('oop-006', $o$Derleme hatası$o$, false, 3),

('oop-006b', $o$Silme ve değiştirme yollarının hepsi kapatılamaz; liste private alanda tutulmalı, dışarıya ekleme ve okuma açılmalı.$o$, true, 0),
('oop-006b', $o$Tasarım yeterlidir ama sınıf final yapılmalıdır; final olmayan bir sınıfta alt sınıflar override edilen metotları geri açabilir.$o$, false, 1),
('oop-006b', $o$Sorun thread-safety'dir; liste Collections.synchronizedList ile sarılırsa eşzamanlı silme denemeleri de engellenmiş olur.$o$, false, 2),
('oop-006b', $o$Override edilen metotlar exception yerine false veya null döndürmelidir; böylece List sözleşmesi bozulmaz ve tasarım güvenli olur.$o$, false, 3),

('oop-007', $o$Sms-object / Sms-object$o$, false, 0),
('oop-007', $o$Notifier-string / Notifier-string$o$, false, 1),
('oop-007', $o$Notifier-object / Notifier-string$o$, false, 2),
('oop-007', $o$Sms-object / Notifier-string$o$, true, 3),

('oop-007b', $o$parent child$o$, true, 0),
('oop-007b', $o$child child$o$, false, 1),
('oop-007b', $o$parent parent$o$, false, 2),
('oop-007b', $o$Derleme hatası$o$, false, 3),

('oop-008', $o$status UserStatus enum'u yapılmalı ve setStatus(UserStatus) korunmalıdır; enum sadece geçerli değerlere izin verdiği için iki sorun da çözülür.$o$, false, 0),
('oop-008', $o$Genel setter kaldırılmalı; durum enum ile tutulmalı ve değişiklik BLOCKED kontrolü yapan activate() gibi domain metotlarıyla yapılmalı.$o$, true, 1),
('oop-008', $o$Alan zaten private olduğu için encapsulation sağlanmıştır; durum geçişleri yönetim aracının controller katmanında kontrol edilmelidir.$o$, false, 2),
('oop-008', $o$setStatus içinde değer izin verilen değerler listesiyle doğrulanmalıdır; geçerli bir değer verildiği sürece durum serbestçe değişebilir.$o$, false, 3),

('oop-008b', $o$Kontrol, tüm servislerin çağırması gereken ortak bir WalletValidator sınıfına taşınmalı, kod incelemelerinde bu çağrı denetlenmelidir.$o$, false, 0),
('oop-008b', $o$Veritabanına bakiyenin eksiye düşmesini engelleyen bir CHECK constraint eklenmeli; kuralın domain kodunda ayrıca tutulması gerekmez.$o$, false, 1),
('oop-008b', $o$Kural Wallet'ın içine alınmalı: withdraw(amount) kontrolü yapıp bakiyeyi düşürmeli, dışarıya açık setBalance metodu kaldırılmalı.$o$, true, 2),
('oop-008b', $o$balance alanı volatile yapılmalıdır; servisler bakiyenin güncel değerini görmediği için kontrol bazen yanlış sonuç verip bakiyeyi eksiye düşürür.$o$, false, 3);

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM questions q
        JOIN oop_questions s ON s.id = q.id
        WHERE q.quiz_id IS DISTINCT FROM (SELECT quiz_id FROM oop_target)
    ) THEN
        RAISE EXCEPTION 'An OOP question ID is already used by another quiz';
    END IF;
END;
$$;

-- Remove only the known questions of the previous OOP quiz version.
CREATE TEMP TABLE oop_legacy_ids (id varchar(50) PRIMARY KEY) ON COMMIT DROP;
INSERT INTO oop_legacy_ids VALUES
    ('pattern-oop-002'), ('solid-oop-003'), ('abstract-oop-004'), ('abstraction-oop-005'),
    ('inheritance-oop-006'), ('polymorphism-oop-007'), ('encapsulation-oop-008'), ('singleton-oop-009'),
    ('srpocpdip-oop-010'), ('lsp-oop-011'), ('isp-oop-012'), ('abstract-oop-013'), ('polymorphism-oop-014');

DELETE FROM options o
USING questions q
WHERE o.question_id = q.id
  AND q.quiz_id = (SELECT quiz_id FROM oop_target)
  AND q.id IN (SELECT id FROM oop_legacy_ids);

DELETE FROM questions q
WHERE q.quiz_id = (SELECT quiz_id FROM oop_target)
  AND q.id IN (SELECT id FROM oop_legacy_ids);

-- Any other question in this quiz was not created by this seed (e.g. added manually); stop instead of deleting it.
DO $$
DECLARE
    unknown_ids text;
BEGIN
    SELECT string_agg(q.id, ', ' ORDER BY q.id) INTO unknown_ids
    FROM questions q
    WHERE q.quiz_id = (SELECT quiz_id FROM oop_target)
      AND q.id NOT IN (SELECT id FROM oop_questions);
    IF unknown_ids IS NOT NULL THEN
        RAISE EXCEPTION 'OOP quiz contains questions not managed by this seed: %', unknown_ids;
    END IF;
END;
$$;

INSERT INTO questions (id, quiz_id, type, text, image_url, code_snippet, explanation, score, sort_order)
SELECT s.id, t.quiz_id, 'mcq', s.text, '', s.code_snippet, s.explanation, 1, s.sort_order
FROM oop_questions s
CROSS JOIN oop_target t
ON CONFLICT (id) DO NOTHING;

-- Refresh wording for all seeded OOP questions.
UPDATE questions q
SET text = s.text,
    code_snippet = s.code_snippet,
    explanation = s.explanation,
    sort_order = s.sort_order
FROM oop_questions s
WHERE q.id = s.id
  AND q.quiz_id = (SELECT quiz_id FROM oop_target)
  AND (q.text, q.code_snippet, q.explanation, q.sort_order)
      IS DISTINCT FROM
      (s.text, s.code_snippet, s.explanation, s.sort_order);

INSERT INTO options (question_id, text, is_correct, match_text, sort_order)
SELECT s.question_id, s.text, s.is_correct, '', s.sort_order
FROM oop_options s
WHERE NOT EXISTS (
    SELECT 1 FROM options o WHERE o.question_id = s.question_id
);

-- Refresh option wording and correct-answer positions for every seeded OOP question.
UPDATE options o
SET text = s.text,
    is_correct = s.is_correct
FROM oop_options s
JOIN questions q ON q.id = s.question_id
WHERE o.question_id = s.question_id
  AND o.sort_order = s.sort_order
  AND q.quiz_id = (SELECT quiz_id FROM oop_target)
  AND (o.text, o.is_correct) IS DISTINCT FROM (s.text, s.is_correct);

DO $$
BEGIN
    IF (SELECT count(*) FROM questions WHERE quiz_id = (SELECT quiz_id FROM oop_target)) <> 16 THEN
        RAISE EXCEPTION 'Expected exactly sixteen questions in the OOP quiz';
    END IF;

    IF EXISTS (
        SELECT q.id
        FROM questions q
        JOIN oop_questions s ON s.id = q.id
        LEFT JOIN options o ON o.question_id = q.id
        GROUP BY q.id
        HAVING count(o.id) <> 4
            OR count(o.id) FILTER (WHERE o.is_correct) <> 1
    ) THEN
        RAISE EXCEPTION 'Each seeded OOP question must have four options and one correct answer';
    END IF;
END;
$$;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM questions
        WHERE quiz_id = (SELECT quiz_id FROM oop_target)
        GROUP BY sort_order
        HAVING count(*) <> 2
    ) THEN
        RAISE EXCEPTION 'Each OOP topic (sort_order) must have exactly two variants';
    END IF;

    IF (SELECT array_agg(DISTINCT sort_order ORDER BY sort_order)
        FROM questions
        WHERE quiz_id = (SELECT quiz_id FROM oop_target)) IS DISTINCT FROM ARRAY[1,2,3,4,5,6,7,8] THEN
        RAISE EXCEPTION 'Expected OOP topic groups 1 to 8';
    END IF;
END;
$$;

COMMIT;
