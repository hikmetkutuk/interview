-- Run explicitly against an existing database; this is not a schema migration.
BEGIN;

INSERT INTO categories (name, slug, description)
VALUES ('OOP', 'oop', 'Nesne yönelimli tasarım, SOLID, tasarım kalıpları ve Java davranışları')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO quizzes (id, title, description, category_id, time_limit_seconds, passing_score)
SELECT 'd348517b-8107-4a22-9bb2-e52ec06c5a58', 'OOP',
       'Senior mülakat: OOP, SOLID, tasarım kalıpları ve Java davranışları üzerine 14 senaryo.',
       id, 2700, 70
FROM categories
WHERE slug = 'oop'
  AND NOT EXISTS (SELECT 1 FROM quizzes WHERE category_id = categories.id AND title = 'OOP');

CREATE TEMP TABLE oop_target ON COMMIT DROP AS
SELECT q.id::varchar(50) AS quiz_id
FROM quizzes q JOIN categories c ON c.id = q.category_id
WHERE c.slug = 'oop' AND q.title = 'OOP';

DO $$
BEGIN
    IF (SELECT count(*) FROM oop_target) <> 1 THEN
        RAISE EXCEPTION 'Expected exactly one OOP quiz';
    END IF;
END;
$$;

UPDATE quizzes
SET description = 'Senior mülakat: OOP, SOLID, tasarım kalıpları ve Java davranışları üzerine 14 senaryo.',
    time_limit_seconds = 2700
WHERE id::text = (SELECT quiz_id FROM oop_target);

CREATE TEMP TABLE oop_questions (
    id varchar(50) PRIMARY KEY,
    text text NOT NULL,
    code_snippet text NOT NULL,
    explanation text NOT NULL,
    sort_order integer NOT NULL UNIQUE
) ON COMMIT DROP;

INSERT INTO oop_questions VALUES
('oop-001',
$q$Bir ödeme sisteminde Payment nesnesi geçersiz durum geçişlerini kendi metotlarıyla engelliyor. CheckoutService yalnızca PaymentGateway sözleşmesini biliyor; kart ve banka havalesi sağlayıcıları bu sözleşmeyi farklı biçimde uyguluyor. Ekip, ortak kodu azaltmak için tüm sağlayıcıları tek bir base class'tan türetmeyi öneriyor. OOP prensipleri açısından en doğru değerlendirme hangisidir?$q$,
'',
$e$OOP'nin dört temel prensibi encapsulation, abstraction, inheritance ve polymorphism'dir. Encapsulation, Payment nesnesinin state'ini ve iş kurallarını korumasıdır; yalnızca alanları private yapmak yeterli değildir. Abstraction, CheckoutService'e sağlayıcının nasıl çalıştığını gizleyen anlamlı bir PaymentGateway sözleşmesi sunar. Polymorphism, bu sözleşme üzerinden farklı sağlayıcı implementasyonlarının kullanılabilmesidir. Inheritance ise gerçek bir is-a ilişkisi ve davranışsal uyumluluk varsa ortak davranış/state devralmayı sağlar; diğer üç prensibi kullanmak için class inheritance zorunlu değildir. Sadece kod tekrarını azaltmak amacıyla kalıtım kurmak güçlü coupling yaratabilir. Ortak bir davranış composition ile paylaşılabilir; sağlayıcının sözleşmenin önkoşullarını ve sonuç garantilerini koruması gerekir.$e$, 1),
('pattern-oop-002',
$q$Bir fiyatlandırma servisinde müşteri segmentine göre değişen indirim algoritmaları var. Algoritma sipariş bazında seçiliyor ve yeni kurallar sık ekleniyor. Algoritmanın oluşturulması da sağlayıcı ayarlarına bağlı. Strategy, Factory Method ve Singleton rollerini en doğru ayıran tasarım hangisidir?$q$,
'',
$e$Design pattern'lar tekrar eden tasarım problemleri için bağlama göre kullanılan çözüm yaklaşımlarıdır. Creational kalıplar nesne oluşturmayı düzenler: Singleton, Factory Method, Abstract Factory, Builder ve Prototype. Structural kalıplar nesnelerin yapısını ve ilişkilerini düzenler: Adapter, Decorator, Facade, Composite ve Proxy. Behavioral kalıplar davranış ve sorumluluk paylaşımını düzenler: Strategy, Observer, Command, Template Method ve Iterator. Strategy, değişen indirim algoritmalarını ortak sözleşme altında kapsüller; algoritmanın seçimi istemciyi concrete sınıflara bağımlı hale getirmeden yapılabilir. Factory Method, oluşturma kararını alt sınıfların özelleştirdiği bir oluşturma noktası sağlar; her factory yardımcı sınıfı GoF Factory Method değildir. Singleton tek instance ve erişim düzenidir, algoritma seçme kalıbı değildir. Thread-safe instance oluşturmak, mutable iş verisini thread-safe yapmaz. DI container'daki singleton lifetime ile global erişimli GoF Singleton da aynı şey değildir. Veritabanı bağlantıları için tek global connection yerine yaşam döngüsü yönetilen bir connection pool genellikle daha uygundur.$e$, 2),
('solid-oop-003',
$q$NotificationService, kanal adına göre if/else ile SMS, e-posta ve push gönderiyor; ayrıca SQL ile alıcıları okuyor ve retry yönetiyor. Yeni kanallar sık ekleniyor. Kanalların bir kısmı teslimat onayı desteklemiyor. SOLID açısından en tutarlı refactoring hangisidir?$q$,
'',
$e$SRP, bir modülün tek bir değişim nedenine odaklanmasıdır: bildirim orkestrasyonu, alıcı saklama ve kanal implementasyonları ayrı sorumluluklardır. OCP, öngörülen değişim noktalarında yeni davranış eklerken mevcut iş akışını sürekli değiştirmemeyi hedefler; yeni NotificationChannel implementasyonu dışarıda kaydedilebilir. LSP, implementasyonların sözleşmeyi korumasıdır: bir kanal önkoşulları güçlendirmemeli veya vaat edilen sonucu zayıflatmamalıdır. Her kanalın kesin teslimatı senkron garanti etmediği bir sistemde sözleşme kabul, hata ve teslimat durumunu açıkça ayırmalıdır. ISP, istemcileri kullanmadıkları yeteneklere bağımlı bırakmamaktır; teslimat onayı ayrı bir capability olabilir. DIP, üst seviye iş akışının SQL veya somut gönderici yerine kendi ihtiyacına uygun abstraction'lara bağımlı olmasıdır. NotificationChannel ve RecipientRepository buna örnektir. Dependency injection bu bağımlılıkları bağlama tekniğidir; tek başına DIP'nin sağlandığını kanıtlamaz. Retry da idempotency ve kanalın hata sözleşmesi dikkate alınarak uygulanmalıdır.$e$, 3),
('abstract-oop-004',
$q$Java'da iki bağımsız SDK'nın sınıfları farklı base class'lardan türemiş. Her ikisi de sisteme birer belge doğrulayıcı olarak eklenecek. Ekip ortak doğrulama sözleşmesi ve yeniden kullanılabilir audit davranışı istiyor. Interface ve abstract class arasında hangi tercih daha uygundur?$q$,
'',
$e$Interface, bağımsız implementasyonları ortak bir contract altında tutmak için uygundur. Java'da bir sınıf birden fazla interface uygulayabilir, ancak yalnızca tek sınıftan türeyebilir. Mevcut SDK sınıfları başka base class'lara bağlı olduğundan adapter'lar ortak Validator interface'ini uygulayabilir; audit davranışı composition veya decorator ile paylaşılabilir. Abstract class, gerçek bir ortak temel ve davranışsal uyumluluk varsa instance state, constructor ve ortak implementasyon sunar; yalnızca kod tekrarını azaltmak için seçilmemelidir. Modern Java interface'leri abstract metotlara ek olarak default, static ve private yardımcı metotlar da içerebilir. Interface instance state veya constructor taşımaz; alanları public static final'dır. Dolayısıyla interface'lerin yalnızca soyut metot içerdiği ya da bütün metotlarının her durumda public olduğu genellemeleri doğru değildir. Default metotlar da abstract class ile aynı state paylaşımını sağlamaz.$e$, 4),
('abstraction-oop-005',
$q$CheckoutService bir PaymentGateway interface'ine bağımlı ve çalışma zamanında farklı sağlayıcılar kullanıyor. Ancak servis her çağrıdan önce instanceof ile sağlayıcı tipini kontrol ederek o sağlayıcıya özel alanları okuyor. Abstraction ve polymorphism açısından sorunu en iyi gideren yaklaşım hangisidir?$q$,
'',
$e$Abstraction, iş akışının ihtiyaç duyduğu anlamlı sözleşmeyi sunar ve implementasyon ayrıntılarını gizler; ne yapıldığını tarif eder. Polymorphism, aynı sözleşmenin farklı implementasyonlar tarafından yerine getirilmesidir; aynı ne için farklı nasıl davranışlarını mümkün kılar. Bir interface tanımlamak, istemcinin concrete tip kontrolleriyle sağlayıcı ayrıntılarına bağımlı kaldığı tasarımda yeterli abstraction sağlamaz. Ortak iş ihtiyacı PaymentRequest ve PaymentResult gibi domain tipleriyle ifade edilebilir; sağlayıcıya özgü çeviriler adapter implementasyonlarında kalır. Contract, desteklenen davranışları ve başarısızlık semantiğini açıkça tanımlamalıdır. Bir sağlayıcının karşılayamadığı kabiliyet bütün implementasyonlara zorlanmamalı; gerekirse capability interface'leri kullanılmalıdır. Base class eklemek ya da her sağlayıcı özelliğini ortak interface'e taşımak bu bağımlılığı kendiliğinden çözmez.$e$, 5),
('inheritance-oop-006',
$q$Rapor dışa aktarma sisteminde CSV, PDF ve JSON exporter'ları aynı base class'ın korumalı mutable alanlarını kullanıyor. Sıkıştırma ve şifreleme seçenekleri eklendikçe her kombinasyon için yeni subclass gerekiyor; bazı işler bu davranışları çalışma zamanında değiştiriyor. Hangi tasarım tercihinin gerekçesi daha güçlüdür?$q$,
'',
$e$Inheritance bir is-a ilişkisidir; alt sınıf üst sınıfın davranış sözleşmesini korumalıdır. Composition ise has-a ilişkisidir: bir nesne ihtiyaç duyduğu davranışı başka nesneler üzerinden kullanır. Export biçimi ile sıkıştırma/şifreleme bağımsız değişim eksenleridir. Bunları bir kalıtım ağacında birleştirmek sınıf kombinasyonlarını çoğaltır; parent'ın protected state ve davranış değişiklikleri child'ları etkiler. Exporter sözleşmesi ile kompozisyon kurulan dönüşümler, uygun strategy/decorator zinciri sayesinde bağımsız test edilebilir ve iş bazında seçilebilir. Sıkıştırma ve şifrelemenin sırası çıktı anlamını değiştirebileceğinden zincirin sırası ve stream yaşam döngüsü de açık olmalıdır. Favor composition over inheritance bir tasarım rehberidir, mutlak yasak değildir. Stabil bir is-a ilişkisi, LSP uyumluluğu ve gerçekten ortak bir temel varsa inheritance hâlâ uygun olabilir.$e$, 6),
('polymorphism-oop-007',
$q$Aşağıdaki Java kodu sırasıyla hangi üç satırı yazdırır? Overload seçimi, runtime dispatch ve static method hiding ayrımını dikkate alın.$q$,
$code$class Base {
    String handle(Object value) { return "Base:Object"; }
    String handle(String value) { return "Base:String"; }
    static String kind() { return "Base"; }
}

class Derived extends Base {
    @Override
    String handle(Object value) { return "Derived:Object"; }
    static String kind() { return "Derived"; }
}

Base service = new Derived();
Object value = "hello";
System.out.println(service.handle(value));
System.out.println(service.handle("hello"));
System.out.println(service.kind());$code$,
$e$Çıktı Derived:Object, Base:String ve Base'dir. Overloading, aynı isimli metotların farklı parametre listeleridir; hangi signature'ın çağrılacağı compile time'da ifadenin statik tiplerinden seçilir. value değişkeni Object olduğundan ilk çağrı handle(Object) signature'ını seçer; runtime dispatch gerçek nesne Derived olduğu için bu signature'ın override edilmiş implementasyonunu çağırır. İkinci çağrıda String literal için handle(String) seçilir ve Derived bu signature'ı override etmediği için Base:String çalışır. Static kind() override edilmez, hide edilir; service'in statik tipi Base olduğundan Base.kind() seçilir. Static metotları sınıf adıyla çağırmak bu ayrımı daha açık yapar. Runtime polymorphism aynı instance metodu sözleşmesine uygun farklı override'ların kullanılmasını sağlar; overload seçimi runtime nesne tipine göre yeniden yapılmaz. Java'da final metot override edilemez; private metot alt sınıfa miras kalan bir override noktası değildir.$e$, 7),
('encapsulation-oop-008',
$q$Aşağıdaki Java sınıfında Line nesnelerinin fiyat/adet alanları değiştirilebiliyor. İş kuralına göre yalnızca DRAFT sipariş düzenlenebilir; boş sipariş CONFIRMED durumuna geçemez ve onay geri alınamaz. Hem koleksiyon sahipliğini hem de durum geçişi kurallarını koruyan tasarım hangisidir?$q$,
$code$class Order {
    private final List<Line> lines;
    private OrderStatus status = OrderStatus.DRAFT;

    Order(List<Line> lines) {
        this.lines = lines;
    }

    List<Line> getLines() {
        return Collections.unmodifiableList(lines);
    }

    void setStatus(OrderStatus status) {
        this.status = status;
    }
}$code$,
$e$Private alan ve getter/setter tek başına güçlü encapsulation değildir. Constructor, dışarıdan gelen mutable listenin referansını saklar; çağıran kişi asıl listeyi değiştirerek Order içeriğini değiştirebilir. Collections.unmodifiableList bir görünüm sağlar; kaynak listeyi kopyalamaz ve mutable Line elemanlarını immutable yapmaz. Girişte defensive copy ve immutable Line value object veya bağımsız eleman kopyası gerekir. List.copyOf gibi shallow copy eleman alias problemini çözmez. Dışarıya immutable elemanlardan oluşan snapshot sunulmalıdır. Genel setStatus yerine confirm() geçişi, siparişin DRAFT ve listesinin dolu olduğunu doğrulayıp CONFIRMED durumuna geçirmelidir. addLine() ve changeQuantity() yalnızca DRAFT durumunda çalışmalı; adet/fiyat kuralları nesnenin içinde korunmalıdır. Constructor da geçerli başlangıç state'i oluşturmalıdır. CONFIRMED nesneyi yeniden DRAFT yapan setter, kontrol edilmiş geçişi sonradan bozar. User.activate() örneğinde de BLOCKED kullanıcının aktive edilmesi domain metodu içinde engellenir. Amaç geçersiz state'i mümkün olduğunca temsil edilemez hale getirmektir; enum ve private alanlar tek başına yeterli değildir. Eşzamanlı erişim varsa atomiklik ayrıca sağlanmalıdır.$e$, 8),
('singleton-oop-009',
$q$Aşağıdaki Singleton farklı request thread'leri tarafından kullanılıyor. Testler de getInstance() çağrısıyla aynı instance'a erişiyor. Güvenli oluşturma, sayaç doğruluğu ve test edilebilirlik açısından en doğru değerlendirme hangisidir?$q$,
$code$class Metrics {
    private static Metrics instance;
    private int requests;

    private Metrics() {}

    static Metrics getInstance() {
        if (instance == null) {
            synchronized (Metrics.class) {
                if (instance == null) {
                    instance = new Metrics();
                }
            }
        }
        return instance;
    }

    void record() { requests++; }
}$code$,
$e$Singleton tek instance ve erişim düzenidir; private constructor, static referans ve erişim metodu bunun klasik bileşenleridir. Bu double-checked locking biçiminde instance volatile olmalıdır: kilit almayan okuma için güvenli yayınlama/görünürlük gerekir. Initialization-on-demand holder veya enum da uygun koşullarda oluşturma alternatifleridir. Oluşturmanın güvenli olması requests++ işlemini atomik yapmaz; sayaç AtomicInteger gibi bir yapı ya da doğru senkronizasyon ister. int alanını volatile yapmak da read-modify-write işlemini atomik hale getirmez. Global getInstance çağrısı bağımlılığı gizler ve testlerin state paylaşmasına neden olabilir. İstemciye Metrics sözleşmesini constructor ile enjekte etmek, testlerde ayrı fake veya instance kullanmayı kolaylaştırır. DI singleton lifetime genellikle container kapsamındadır; JVM genelinde veya cluster genelinde tek instance garantisi değildir. Sipariş/request state'i singleton'da tutulmamalı; kaynak yaşam döngüsü açıkça yönetilmelidir. Tek global veritabanı connection'ı yerine connection pool kullanılabilir.$e$, 9),
('srpocpdip-oop-010',
$q$InvoiceService faturayı hesaplıyor, PDF üretiyor ve SMTP ile gönderiyor. Constructor'a somut SmtpMailer enjekte ediliyor; bu sınıfın interface'i de SMTP host/port ayarlarını istemciye açıyor. Yeni çıktı biçimleri ve gönderim kanalları eklenecek. SRP, OCP ve DIP'yi birlikte en doğru uygulayan tasarım hangisidir?$q$,
'',
$e$SRP bir sınıfın tek metoda sahip olması değil, değişim nedenlerinin tutarlı olmasıdır: fatura hesaplama, belge sunumu ve teslimat farklı aktörlerin gereksinimleriyle değişebilir. InvoiceService iş akışını koordine edebilir; format üretimi ve kanal ayrıntıları ayrı implementasyonlarda kalmalıdır. OCP beklenen format/kanal değişimleri için genişleme noktası sunmaktır: InvoiceRenderer ve InvoiceDelivery implementasyonları dışarıda bağlanabilir. Yeni tür geldiğinde her mevcut sınıfı değiştirmemek hedeflenir; konfigürasyon veya composition root'un değişmesi bu hedefle çelişmez. DIP yalnızca constructor injection veya interface kullanmak değildir. Üst seviye politika, SMTP alanlarını açan altyapı sözleşmesine bağımlıysa detaylar hâlâ iş akışına sızar. İş katmanının ihtiyacına göre tanımlanan teslimat sözleşmesiyle altyapı adapter'ları bu soyutlamaya bağımlı olur; bağımlılık yönü değişir. Gereksiz bir interface katmanı veya tek devasa strategy aynı ayrımı sağlamaz. Bu prensipler gerçek değişim noktalarına göre uygulanmalıdır.$e$, 10),
('lsp-oop-011',
$q$Account.withdraw(amount) sözleşmesi, her pozitif ve bakiyeyi aşmayan tutarı kabul eder; başarılı çağrı bakiyeyi tam amount kadar azaltır. Yeni PremiumAccount, bakiyesi yeterli olsa bile 100'den küçük çekimleri reddediyor. Başka bir subclass ise aynı amount için ek ücret kesiyor. LSP açısından hangi değerlendirme doğrudur?$q$,
'',
$e$LSP, üst tipin davranış sözleşmesine güvenen istemcinin alt tipi de kullanabilmesidir; aynı method signature veya derlenebilir kalıtım yeterli değildir. PremiumAccount'ın minimum 100 koşulu üst sözleşmenin kabul ettiği girdileri reddederek önkoşulu güçlendirir. Ek ücret bakiyeyi tam amount kadar azaltma garantisini bozarak sonkoşulu karşılamaz. Daha zayıf önkoşullar ve daha güçlü sonuç garantileri, diğer invariant ve history koşulları korunuyorsa uyumlu olabilir. Domain gerçekten minimum çekim veya ücret istiyorsa bu kurallar ayrı policy/contract ile modellenebilir; üst sözleşme açıkça yeniden tasarlanmalıdır. İstemcide instanceof kontrolleri eklemek substitutability problemini gizler. Benzer şekilde her Bird için fly() vaat eden bir contract'a uçamayan Penguin eklemek yerine flying capability ayrı tutulabilir. LSP salt inheritance eleştirisi değildir; interface implementasyonlarının kabul, hata, sonuç ve state garantileri de aynı açıdan değerlendirilir.$e$, 11),
('isp-oop-012',
$q$DocumentStore sözleşmesi read, write, delete ve watch işlemlerinin tamamını desteklemeyi vaat ediyor. ReadOnlyArchive sadece read yapabildiği için diğer metotlarda UnsupportedOperationException fırlatıyor. Raporlama istemcisi yalnızca read kullanıyor; arşiv sağlayıcısı watch yeteneğini hiçbir zaman desteklemeyecek. ISP ve sözleşme uyumu açısından en uygun düzenleme hangisidir?$q$,
'',
$e$ISP, istemcileri ihtiyaç duymadıkları metot ve değişimlere bağımlı bırakmamaktır; amaç her metot için otomatik bir interface oluşturmak değildir. İstemci ihtiyacı ve tutarlı capability sınırları temel alınır. Raporlama DocumentReader'a, düzenleyici DocumentWriter gibi uygun sözleşmelere bağımlı olabilir; watch ayrı capability olarak modellenebilir. Tam özellikli sağlayıcı birden fazla interface uygulayabilir, ReadOnlyArchive yalnızca gerçekten sağladığı capability'yi sunar. Desteklenmeyen metotlara boş gövde veya UnsupportedOperationException koymak, bütün işlemleri desteklemeyi vaat eden bu contract'ı karşılamaz. Eğer bir API optional operation'ları açıkça sözleşmesinde tanımlıyorsa değerlendirme farklıdır; burada böyle bir sözleşme yoktur. Default metotla hata fırlatmak sadece implementasyon yükünü azaltır, ISP/LSP sorununu gidermez. Capability desteği uygulamanın composition sınırında belirlenmeli; dar sözleşmeye bağımlı istemci tekrar concrete provider türünü kontrol etmek zorunda kalmamalıdır.$e$, 12),
('abstract-oop-013',
$q$Aşağıdaki Java kodunda new Validator("acme").audit() ne döndürür? Ayrıca BaseValidator.audit() tamamen kaldırılırsa Validator değiştirilmeden derlenebilir mi?$q$,
$code$interface LeftAudit {
    default String audit() { return "left"; }
}

interface RightAudit {
    default String audit() { return "right"; }
}

abstract class BaseValidator {
    private final String tenant;
    BaseValidator(String tenant) { this.tenant = tenant; }
    public final String audit() { return tenant; }
}

class Validator extends BaseValidator implements LeftAudit, RightAudit {
    Validator(String tenant) { super(tenant); }
}$code$,
$e$Mevcut kod acme döndürür. Superclass'tan gelen concrete public audit metodu iki interface'in default metoduna göre önceliklidir ve interface sözleşmelerini karşılar. final olması subclass override'ını engeller; interface'i karşılamasını engellemez. BaseValidator constructor ve instance state taşır; abstract olması constructor'ının çağrılmasına engel değildir. audit superclass'tan tamamen kaldırıldığında ilgisiz iki interface aynı signature için default implementasyon sunar ve Validator bunları kendiliğinden seçemez: derleme hatası oluşur. Validator açık public override ile kendi davranışını yazabilir veya LeftAudit.super.audit() gibi açık seçim yapabilir. Interface sırası seçim kuralı değildir. Interface default davranış sunabilir, ancak instance alanı veya constructor sağlayamaz; static metotları interface adıyla çağrılır, private yardımcı metotları implementasyon detaylarıdır. Güçlü ve uyumlu bir ortak temel varsa abstract class, bağımsız capability/contract gerekiyorsa interface uygundur.$e$, 13),
('polymorphism-oop-014',
$q$Aşağıdaki Java kodunda base.render() ve child.label() sırasıyla ne döndürür? Child.label() üzerine @Override eklemek veya Child içinde render() metodu tanımlamak açısından hangi değerlendirme doğrudur?$q$,
$code$class Parent {
    private String label() { return "Parent"; }
    public final String render() { return label(); }
}

class Child extends Parent {
    public String label() { return "Child"; }
}

Parent base = new Child();
Child child = new Child();
System.out.println(base.render());
System.out.println(child.label());$code$,
$e$Çıktı Parent ve Child'dır. Parent.label private olduğu için Child'a miras kalan bir override noktası değildir; Child.label aynı isim ve parametreleri taşıyan bağımsız bir metottur. Parent.render içindeki private çağrı Child.label'a dispatch edilmez. Bu örnekte Child.label üzerine @Override eklemek derleme hatasıdır, çünkü başka bir üst sözleşmeyi de uygulamamaktadır. Parent.render public final olduğundan Child aynı signature'la onu override edemez. Final metot içinden başka bir overridable instance metodu çağrılsaydı o çağrı runtime dispatch kullanabilirdi; final olması bütün iç çağrıları statik hale getirmez. Önceki kod sorusundaki static metotlar ise override değil method hiding yapar. Overloading farklı parametre listeleriyle compile-time seçimdir. Java override kuralları ayrıca görünürlüğü daraltmayı ve checked exception kapsamını genişletmeyi engeller; uygun covariant dönüş tipi mümkündür. Runtime polymorphism davranış sözleşmesine uygun instance override'larıyla çalışır.$e$, 14);

CREATE TEMP TABLE oop_options (
    question_id varchar(50) NOT NULL REFERENCES oop_questions(id),
    text text NOT NULL,
    is_correct boolean NOT NULL,
    sort_order integer NOT NULL,
    PRIMARY KEY (question_id, sort_order)
) ON COMMIT DROP;

INSERT INTO oop_options VALUES
('oop-001', 'Interface abstraction sağlar; polymorphism için sağlayıcıların mutlaka ortak bir concrete base class üzerinden davranış devralması gerekir.', false, 0),
('oop-001', 'Durum kurallarını nesnenin koruması encapsulation, sağlayıcı ayrıntılarını sözleşmenin gizlemesi abstraction, farklı sağlayıcıların aynı sözleşmeyi karşılaması polymorphism''dir; inheritance ayrıca gerçek bir is-a ilişkisi gerektirir.', true, 1),
('oop-001', 'Tüm sağlayıcıları aynı base class''tan türetmek substitution uyumluluğunu garanti eder; ortak protected alanlar state bütünlüğünü korumak için yeterlidir.', false, 2),
('oop-001', 'Ödeme durum kurallarını CheckoutService''e taşımak encapsulation''ı güçlendirir; Payment böylece yalnızca veri taşıdığı için implementasyon ayrıntıları gizlenmiş olur.', false, 3),
('pattern-oop-002', 'Siparişe ait indirim state''ini Singleton üzerinde tutup algoritmayı her çağrıda değiştirmek, thread-safe instance oluşturulduğu sürece güvenlidir.', false, 0),
('pattern-oop-002', 'Factory Method indirim davranışını çalışma zamanında yürütmeli, Strategy ise yalnızca nesne oluşturmalı; böylece iki değişim noktası ayrılır.', false, 1),
('pattern-oop-002', 'Her algoritmayı ayrı Singleton yapmak seçim ihtiyacını ortadan kaldırır; istemcinin concrete singleton''ları bilmesi abstraction sınırını etkilemez.', false, 2),
('pattern-oop-002', 'İndirim davranışlarını Strategy ile ayırmak, oluşturma kararını uygun bir factory/DI sınırına taşımak ve sipariş state''ini paylaşmamak uygundur; Singleton bu iki sorumluluğun yerine geçmez.', true, 3),
('solid-oop-003', 'Orkestrasyonu kanal ve repository abstraction''larına bağlamak, yeni kanalı dışarıda kaydetmek, teslimat onayını ayrı capability yapmak ve tüm kanallarda ortak sonuç/hata sözleşmesini korumak.', true, 0),
('solid-oop-003', 'Her concrete sınıfa bir interface ekleyip mevcut if/else ve SQL sorgularını NotificationService içinde bırakmak; interface kullanımı SRP, OCP ve DIP için yeterlidir.', false, 1),
('solid-oop-003', 'send(), confirmDelivery() ve refund() içeren tek geniş interface oluşturmak; desteklenmeyen metotlarda UnsupportedOperationException fırlatmak LSP''yi sağlar.', false, 2),
('solid-oop-003', 'Kanalları tek abstract class''tan türetip bütün kanallarda başarılı send() dönüşünü kesin teslimat olarak tanımlamak; provider farklılıklarını subclass''lara bırakmak.', false, 3),
('abstract-oop-004', 'Audit kodunu paylaşmak için tek abstract Validator zorunludur; SDK sınıfları adapter kullanılsa bile mevcut base class ilişkilerini bırakmalıdır.', false, 0),
('abstract-oop-004', 'Interface''e default audit metodu eklemek, her validator için ayrı instance state ve constructor tanımlamaya olanak verdiğinden abstract class''ın tüm imkânlarını sağlar.', false, 1),
('abstract-oop-004', 'Bağımsız implementasyonları Validator interface''iyle birleştirmek, SDK''ları adapter ile sarmalamak ve audit''i composition/decorator ile paylaşmak; abstract class''ı ancak gerçek bir ortak temel gerekiyorsa kullanmak.', true, 2),
('abstract-oop-004', 'Her SDK için ayrı contract tanımlayıp istemcinin concrete validator tiplerini seçmesini sağlamak; ortak abstraction''ı instanceof kontrolleriyle client içinde kurmak.', false, 3),
('abstraction-oop-005', 'instanceof kontrollerini bir yardımcı metoda taşımak yeterlidir; interface mevcut olduğu için istemci zaten sağlayıcı ayrıntılarından soyutlanmıştır.', false, 0),
('abstraction-oop-005', 'İş ihtiyacına uygun giriş/sonuç ve hata sözleşmesini tanımlamak, sağlayıcıya özgü çeviriyi adapter''larda tutmak ve desteklenmeyen kabiliyetleri zorunlu ortak sözleşmeye eklememek.', true, 1),
('abstraction-oop-005', 'Bütün sağlayıcıya özgü alanları PaymentGateway''e getter olarak eklemek; böylece istemci cast yapmadan concrete sağlayıcı ayrıntılarını okuyabilir.', false, 2),
('abstraction-oop-005', 'Interface yerine aynı metotları taşıyan bir abstract class kullanmak; çağrı öncesi sağlayıcı tipi kontrollerini korumak runtime polymorphism''i yeterli hale getirir.', false, 3),
('inheritance-oop-006', 'Subclass''ları ortak state''e daha rahat eriştirmek için protected alanları public yapmak; hiyerarşiyi koruyup kombinasyon sayısını factory ile yönetmek.', false, 0),
('inheritance-oop-006', 'Her bağımsız davranış için ara base class eklemek; tek kalıtım zincirindeki sıkıştırma ve şifreleme sırası çalışma zamanında yeniden düzenlenebilir.', false, 1),
('inheritance-oop-006', 'Tüm seçenekleri tek exporter''daki boolean flag''lerle yönetmek; composition eklemek yerine if/else dallarını base class''ta toplamak OCP''yi sağlar.', false, 2),
('inheritance-oop-006', 'Export biçimini ayrı contract ile tanımlamak, sıkıştırma/şifrelemeyi sırası açık strategy veya decorator bileşenleriyle birleştirmek; kalıtımı gerçek ve stabil is-a ilişkileriyle sınırlamak.', true, 3),
('polymorphism-oop-007', 'Derived:Object / Base:String / Base', true, 0),
('polymorphism-oop-007', 'Base:Object / Base:String / Base', false, 1),
('polymorphism-oop-007', 'Base:String / Base:String / Derived', false, 2),
('polymorphism-oop-007', 'Derived:Object / Base:String / Derived', false, 3),
('encapsulation-oop-008', 'Constructor''da List.copyOf kullanmak ve status''ü enum yapmak; setStatus ile geri dönüşleri serbest bırakmak, çünkü enum geçersiz durum geçişlerini de engeller.', false, 0),
('encapsulation-oop-008', 'Line elemanlarını immutable yapmak ve confirm() içinde boş listeyi doğrulamak; constructor''dan gelen liste alias''ını ve sonradan DRAFT''a dönme setter''ını korumak.', false, 1),
('encapsulation-oop-008', 'Liste ve eleman sahipliğini korumak, immutable snapshot sunmak, confirm() içinde DRAFT ve dolu liste koşullarını doğrulamak; düzenlemeyi yalnızca DRAFT''ta yapan domain metotlarıyla sınırlandırıp genel status setter''ını kaldırmak.', true, 2),
('encapsulation-oop-008', 'Kontrolleri controller katmanında yapmak; Order''ı private alanlar ve genel setter''larla veri taşıyıcı tutmak, çünkü domain nesnesi her çağrının controller''dan geleceğini varsayabilir.', false, 3),
('singleton-oop-009', 'instance''ı volatile yapmak oluşturma kadar requests++ için de atomiklik sağlar; testler singleton state''ini sıfırlayarak bağımsızlığı garanti eder.', false, 0),
('singleton-oop-009', 'double-checked locking için instance''ı volatile yapmak veya holder kullanmak, sayacı ayrıca atomik/senkron yönetmek ve istemciye bağımlılığı enjekte etmek; DI singleton kapsamını container''a göre değerlendirmek.', true, 1),
('singleton-oop-009', 'Sadece requests alanını volatile yapmak; constructor private olduğu için instance''ın güvenli yayınlanması ve sayaç artışının atomikliği zaten garanti edilir.', false, 2),
('singleton-oop-009', 'DI container''da singleton tanımlamak hem cluster''da tek instance hem de bütün mutable alanlarda thread safety sağlar; testlerde aynı global nesneyi kullanmak uygundur.', false, 3),
('srpocpdip-oop-010', 'SmtpMailer''ı constructor''a enjekte etmeyi sürdürmek; yeni format ve kanal dallarını InvoiceService''e eklemek, çünkü injection tek başına DIP ve OCP''yi sağlar.', false, 0),
('srpocpdip-oop-010', 'Her metodu bir sınıfa taşımak ve bütün sınıfları SMTP ayarlarını içeren ortak interface''e bağlamak; metot başına sınıf SRP''yi ve interface sayısı DIP''yi belirler.', false, 1),
('srpocpdip-oop-010', 'PDF ve SMTP kodunu tek InvoiceStrategy içinde toplamak, yeni kanal geldikçe mevcut strategy''yi değiştirmek; ortak kodu tek yerde tutmak OCP için yeterlidir.', false, 2),
('srpocpdip-oop-010', 'Hesaplama, sunum ve teslimat değişim nedenlerini ayırmak; iş ihtiyacına göre renderer/delivery contract''ları tanımlayıp adapter''ları bunlara bağlamak ve yeni implementasyonları composition root''ta seçmek.', true, 3),
('lsp-oop-011', 'İki subclass da sözleşmeyi bozar: minimum tutar eklemek önkoşulu güçlendirir, ek ücret ise tam amount kadar azaltma sonkoşulunu karşılamaz; kurallar ayrı policy/contract ile modellenmelidir.', true, 0),
('lsp-oop-011', 'Yalnızca PremiumAccount sözleşmeyi bozar; ek ücret bakiyeyi daha çok azalttığı için üst sınıfın sonkoşulunu her durumda güçlendirmiş olur.', false, 1),
('lsp-oop-011', 'Yalnızca ücretli subclass sözleşmeyi bozar; alt sınıfın daha az girdi kabul etmesi üst sınıfın önkoşulunu zayıflatır ve LSP''ye uygundur.', false, 2),
('lsp-oop-011', 'İki subclass da uygundur; method signature aynı kaldığı ve reddedilen işlemler exception ile bildirildiği sürece LSP korunur.', false, 3),
('isp-oop-012', 'write/delete/watch için default metotlarla aynı exception''ı fırlatmak; çağrı olmadıkça contract uyumu sağlanmış sayılır.', false, 0),
('isp-oop-012', 'İstemcileri ihtiyaç duydukları reader/writer/watch capability contract''larına bağlamak; ReadOnlyArchive yalnızca reader''ı, tam sağlayıcılar gereken birden fazla contract''ı uygulasın.', true, 1),
('isp-oop-012', 'DocumentStore''a canWrite/canDelete/canWatch eklemek; bütün istemcilerin her çağrıdan önce sağlayıcı capability''lerini sorgulamasını zorunlu kılmak.', false, 2),
('isp-oop-012', 'ReadOnlyArchive''da desteklenmeyen işlemleri sessizce başarılı döndürmek; böylece geniş interface korunur ve istemci exception ile karşılaşmaz.', false, 3),
('abstract-oop-013', 'Mevcut kod left döndürür; superclass metodu kaldırıldığında implements listesindeki ilk interface otomatik olarak seçilir.', false, 0),
('abstract-oop-013', 'Mevcut kod derlenmez; final superclass metodu, interface default metotlarının aynı signature ile var olmasını engeller.', false, 1),
('abstract-oop-013', 'Mevcut kod acme döndürür; concrete superclass metodu kaldırılınca ilgisiz default metotlar çakışır ve Validator açık override yazmadan derlenmez.', true, 2),
('abstract-oop-013', 'Mevcut kod acme döndürür; superclass metodu kaldırıldığında JVM çalışma zamanında tenant değerine göre default implementasyonu seçer.', false, 3),
('polymorphism-oop-014', 'Child / Child; private Parent.label runtime''da override edilir, @Override yalnızca görünürlük farkını belgelemek için eklenebilir.', false, 0),
('polymorphism-oop-014', 'Parent / Parent; render final olduğu için Child üzerindeki tüm instance çağrıları Parent implementasyonlarına statik bağlanır.', false, 1),
('polymorphism-oop-014', 'Parent / Child; Child.label bağımsızdır ancak Parent.render yalnızca doğrudan Parent instance''larında final olduğundan Child onu override edebilir.', false, 2),
('polymorphism-oop-014', 'Parent / Child; Child.label private Parent.label''ı override etmez, üzerine @Override eklemek hatadır ve public final render aynı signature ile override edilemez.', true, 3);

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM questions q JOIN oop_questions s ON s.id = q.id
        WHERE q.quiz_id IS DISTINCT FROM (SELECT quiz_id FROM oop_target)
    ) THEN
        RAISE EXCEPTION 'An OOP question ID is already used by another quiz';
    END IF;
END;
$$;

-- Preserve existing content except the explicitly expanded encapsulation scenario.
INSERT INTO questions (id, quiz_id, type, text, image_url, code_snippet, explanation, score, sort_order)
SELECT s.id, t.quiz_id, 'mcq', s.text, '', s.code_snippet, s.explanation, 1, s.sort_order
FROM oop_questions s CROSS JOIN oop_target t
ON CONFLICT (id) DO NOTHING;

UPDATE questions q
SET text = s.text, code_snippet = s.code_snippet, explanation = s.explanation
FROM oop_questions s
WHERE q.id = s.id AND s.id = 'encapsulation-oop-008'
  AND q.quiz_id = (SELECT quiz_id FROM oop_target)
  AND (q.text, q.code_snippet, q.explanation) IS DISTINCT FROM (s.text, s.code_snippet, s.explanation);

INSERT INTO options (question_id, text, is_correct, match_text, sort_order)
SELECT s.question_id, s.text, s.is_correct, '', s.sort_order
FROM oop_options s
WHERE NOT EXISTS (SELECT 1 FROM options o WHERE o.question_id = s.question_id);

UPDATE options o
SET text = s.text, is_correct = s.is_correct
FROM oop_options s
WHERE o.question_id = s.question_id AND o.sort_order = s.sort_order
  AND s.question_id = 'encapsulation-oop-008'
  AND (o.text, o.is_correct) IS DISTINCT FROM (s.text, s.is_correct);

DO $$
BEGIN
    IF (SELECT count(*) FROM questions WHERE quiz_id = (SELECT quiz_id FROM oop_target)) <> 14 THEN
        RAISE EXCEPTION 'Expected exactly fourteen questions in the OOP quiz';
    END IF;
    IF EXISTS (
        SELECT q.id FROM questions q
        JOIN oop_questions s ON s.id = q.id
        LEFT JOIN options o ON o.question_id = q.id
        GROUP BY q.id
        HAVING count(o.id) <> 4 OR count(o.id) FILTER (WHERE o.is_correct) <> 1
    ) THEN
        RAISE EXCEPTION 'Each seeded OOP question must have four options and one correct answer';
    END IF;
END;
$$;

COMMIT;
