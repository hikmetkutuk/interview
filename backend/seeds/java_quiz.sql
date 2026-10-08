-- Java quiz seed
-- 24 senaryo tabanlı Core Java sorusu: 12 konu x 2 varyant.
-- Aynı konunun iki varyantı aynı sort_order değerini paylaşır (ör. java-001 ve java-001b).
-- Uygulama, her sort_order grubundan rastgele bir soru seçerek 12 soruluk bir sınav oluşturmalıdır.
-- Run explicitly against an existing database; this is not a schema migration.

BEGIN;

INSERT INTO categories (name, slug, description)
VALUES ('Java', 'java', 'Core Java, koleksiyonlar, bellek yönetimi, exception yönetimi ve dil davranışları')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO quizzes (id, title, description, category_id, time_limit_seconds, passing_score)
SELECT 'e7a6f6ad-4f5d-4e30-a2ab-9c9b431b4d51', 'Java',
       'Senior mülakat: Core Java üzerine 12 senaryo.',
       id, 2400, 70
FROM categories
WHERE slug = 'java'
  AND NOT EXISTS (SELECT 1 FROM quizzes WHERE category_id = categories.id AND title = 'Java');

CREATE TEMP TABLE java_target ON COMMIT DROP AS
SELECT q.id::varchar(50) AS quiz_id
FROM quizzes q
JOIN categories c ON c.id = q.category_id
WHERE c.slug = 'java' AND q.title = 'Java';

DO $$
BEGIN
    IF (SELECT count(*) FROM java_target) <> 1 THEN
        RAISE EXCEPTION 'Expected exactly one Java quiz';
    END IF;
END;
$$;

UPDATE quizzes
SET description = 'Senior mülakat: Core Java üzerine 12 senaryo.',
    time_limit_seconds = 2400
WHERE id::text = (SELECT quiz_id FROM java_target);

CREATE TEMP TABLE java_questions (
    id varchar(50) PRIMARY KEY,
    text text NOT NULL,
    code_snippet text NOT NULL,
    explanation text NOT NULL,
    sort_order integer NOT NULL
) ON COMMIT DROP;

INSERT INTO java_questions VALUES

('java-001',
$q$Bir log servisinde aşağıdaki metot, her istek için bir özet mesaj üretiyor. Servis çok sayıda thread ile çalıştığı için bir ekip arkadaşınız StringBuilder yerine StringBuffer kullanılmasını öneriyor. Bu öneriyle ilgili en doğru değerlendirme hangisidir?$q$,
$code$String buildSummary(List<LogEntry> entries) {
    StringBuilder sb = new StringBuilder();
    for (LogEntry e : entries) {
        sb.append(e.level()).append(" - ").append(e.message()).append('\n');
    }
    return sb.toString();
}$code$,
$e$StringBuilder metodun içinde oluşturulan yerel bir değişkendir. Her çağrı kendi nesnesini oluşturur ve bu nesne başka bir thread'e verilmez, bu yüzden thread-safety gerekmez. StringBuffer'ın metotları synchronized olduğu için burada sadece gereksiz bir maliyet ekler. Metodu synchronized yapmak da gereksizdir ve tüm çağrıları sıraya sokar. Java 9+ derleyicisinin + optimizasyonu ise tek bir ifade içindir; döngünün iterasyonları arasında ortak bir buffer kullanılmaz, bu yüzden döngüde String birleştirmek her adımda kopyalama yapar.$e$, 1),

('java-002',
$q$Bir API gateway, her endpoint'e gelen istek sayısını bellekte tutuyor. Sayaçlar önce HashMap ile tutuluyordu ve yük altında access log'lardakinden düşük çıkıyordu. Ekip map'i ConcurrentHashMap ile değiştirdi, ancak sayılar hâlâ eksik çıkıyor. Sorunun nedeni ve doğru düzeltme hangisidir?$q$,
$code$private final Map<String, Integer> counts = new ConcurrentHashMap<>();

void record(String endpoint) {
    counts.put(endpoint, counts.getOrDefault(endpoint, 0) + 1);
}$code$,
$e$ConcurrentHashMap'in getOrDefault ve put metotları tek tek thread-safe'tir, ancak ikisi art arda çağrıldığında aralarında başka bir thread aynı değeri okuyup yazabilir ve artışlardan biri kaybolur. merge(endpoint, 1, Integer::sum) okuma ve yazmayı tek bir atomik işlemde yapar. Değer tipini AtomicInteger yapmak tek başına yetmez; put ile yeni nesne yazılmaya devam edildiği sürece aynı yarış sürer, doğru kullanım computeIfAbsent(...).incrementAndGet() olurdu. Segment bazlı kilitleme Java 7'ye aittir ve concurrencyLevel Java 8'den beri sadece başlangıç boyutunu etkiler. Okumaların kilitsiz olması da sorunun kaynağı değildir.$e$, 2),

('java-003',
$q$Eski bir kod tabanında, dosya dışa aktarma işini yapan bir sınıf inceleniyor. Sınıfta private final List<String> buffer alanı var ve dosya, finalize() metodu içinde kapatılıyor. Ekipten biri iki şey söylüyor: buffer final olduğu için içeriği değiştirilemez ve finalize sayesinde dosya her zaman kapanır. Bu iddialarla ilgili en doğru değerlendirme hangisidir?$q$,
'',
$e$final bir alan sadece referansın yeniden atanmasını engeller; referansın gösterdiği listeye eleman eklenebilir. finalize'ın ne zaman çalışacağı, hatta çalışıp çalışmayacağı garanti değildir. Java 9'da deprecated olmuş, Java 18'de kaldırılmak üzere işaretlenmiştir (JEP 421). Kaynaklar try-with-resources ile, deterministik olarak kapatılmalıdır. finally bloğu çoğu durumda çalışır, ancak System.exit çağrısında veya JVM çöktüğünde çalışmaz.$e$, 3),

('java-004',
$q$Bir ekip, log'lara yazılan nesnelerdeki hassas alanları maskelemek için @Masked adında bir annotation tanımladı. Ortak bir yardımcı sınıf, reflection ile bu annotation'ı taşıyan alanları bulup değerlerini gizliyor. Ancak testlerde hiçbir alan maskelenmiyor. Bunun en olası nedeni nedir?$q$,
$code$@Target(ElementType.FIELD)
public @interface Masked {}

public class Customer {
    private String name;
    @Masked private String identityNumber;
}

for (Field field : obj.getClass().getDeclaredFields()) {
    if (field.isAnnotationPresent(Masked.class)) {
        mask(field, obj);
    }
}$code$,
$e$Bir annotation'da @Retention belirtilmezse varsayılan RetentionPolicy.CLASS kullanılır. Bu durumda annotation class dosyasına yazılır ama runtime'da yüklenmez, isAnnotationPresent her zaman false döner. Runtime'da reflection ile okunabilmesi için @Retention(RetentionPolicy.RUNTIME) gerekir. getDeclaredFields private alanlar dahil sınıfta tanımlanan tüm alanları listeler. setAccessible(true) sadece alanın değerini okumak veya değiştirmek için gerekir, annotation'ları okumak için gerekmez. Annotation processor'lar compile-time'da çalışır ve runtime okumasıyla ilgisi yoktur.$e$, 4),

('java-005',
$q$Bir raporlama servisinde heap kullanımı gün boyunca sürekli artıyor. Heap dump'ta, işi çoktan bitmiş ve büyük veri tutan çok sayıda ReportGenerator nesnesi görülüyor. Kod incelendiğinde, satırları temsil eden Row sınıfının ReportGenerator içinde static olmayan bir inner class olarak tanımlandığı ve oluşturulan Row nesnelerinin tekrar kullanılmak üzere static bir cache'te saklandığı görülüyor. ReportGenerator nesnelerinin bellekte kalmasının nedeni nedir?$q$,
$code$public class ReportGenerator {
    private static final Map<String, Row> ROW_CACHE = new ConcurrentHashMap<>();
    private final byte[] rawData; // büyük veri

    class Row {
        String label;
    }

    Row rowFor(String label) {
        return ROW_CACHE.computeIfAbsent(label, l -> new Row());
    }
}$code$,
$e$Static olmayan bir inner class'ın her nesnesi, kendisini oluşturan dış sınıf nesnesine gizli bir referans tutar. Static cache bir GC root'tur; cache'teki Row nesneleri canlı kaldıkça onları oluşturan ReportGenerator nesneleri ve tuttukları büyük veri de canlı kalır. Row static nested class yapılırsa bu gizli referans ortadan kalkar. Inner class için ayrı ayrı sınıf yüklenmez, bu bir Metaspace sorunu değildir. Static alanlar thread başına kopyalanmaz.$e$, 5),

('java-006',
$q$Bir stok servisinde ürünleri depo bazında takip etmek için Map<ProductKey, Integer> kullanılıyor. ProductKey sınıfı sku ve warehouse alanlarını karşılaştıran bir equals metodu içeriyor, ancak hashCode override edilmemiş. Stok eklendikten sonra aynı değerlerle yeni bir key oluşturulup sorgulandığında sonuç çoğu zaman null dönüyor. Bunun nedeni nedir?$q$,
$code$map.put(new ProductKey("A1", "IST"), 5);

Integer stock = map.get(new ProductKey("A1", "IST")); // çoğu zaman null$code$,
$e$HashMap önce hashCode ile bucket'ı bulur, sonra o bucket içinde equals ile karşılaştırma yapar. hashCode override edilmezse Object'in varsayılan implementasyonu kullanılır ve mantıksal olarak eşit iki nesne genellikle farklı hash değerleri üretir. get çağrısı farklı bir bucket'a baktığı için equals hiç çağrılmaz. equals'ı override eden bir sınıf, aynı alanları kullanarak hashCode'u da override etmelidir. equals'ın Objects.equals ile yazılması bunu değiştirmez. HashMap compareTo kullanmaz; Comparable sadece çok dolu bucket'lar ağaca dönüştüğünde sıralama için yardımcı olur.$e$, 6),

('java-007',
$q$Bir kod incelemesinde, junior bir geliştirici aşağıdaki metot çalışırken değişkenlerin ve nesnelerin bellekte nerede durduğunu açıklıyor. Hangi açıklama doğrudur?$q$,
$code$void handle(Request req) {
    int retries = 3;
    Order order = new Order(req.id());
    order.setAttempts(retries); // attempts, Order içinde int bir alan
    queue.submit(order);
}$code$,
$e$Kavramsal JVM bellek modelinde retries ve order metodun local değişkenleridir ve çalışan thread'in stack frame'ine aittir; order'ın değeri sadece bir referanstır. Pratikte JIT bu local değerleri CPU register'ında da tutabilir, ama bu kavramsal modeli değiştirmez. new ile oluşturulan Order nesnesi heap'tedir ve nesnenin primitive alanları, attempts dahil, nesneyle birlikte heap'te yaşar. Metot bittiğinde stack frame kaldırılır, ancak queue nesneye referans tuttuğu sürece GC onu toplamaz. Heap'teki nesneler stack frame ile birlikte silinmez. Bir değişkenin değişmemesi onu heap'e veya constant pool'a taşımaz.$e$, 7),

('java-008',
$q$Bir ödeme istemcisi, dış servise yapılan çağrılarda oluşan IOException'ları aşağıdaki gibi ele alıyor. Merkezi exception handler da gelen her hatayı logluyor. Production'da bir hata oluştuğunda loglarda "Payment failed" mesajı iki kez görünüyor, ama hatanın kök nedenine dair hiçbir bilgi yok. En doğru düzeltme hangisidir?$q$,
$code$try {
    return httpClient.send(request);
} catch (IOException e) {
    log.error("Payment failed");
    throw new PaymentException("Payment failed");
}$code$,
$e$Yeni exception oluşturulurken orijinal exception cause olarak verilmezse kök neden ve stack trace kaybolur. Doğrusu new PaymentException("Payment failed", e) yazmaktır. Ayrıca aynı hata hem burada hem merkezi handler'da loglandığı için iki kez görünüyor; loglama, hatanın son ele alındığı tek bir yerde yapılmalıdır. printStackTrace logging altyapısını atlar ve merkezi log toplama sistemlerine düzgün ulaşmaz. Exception'ı checked yapmak cause'un kaybolmasını engellemez. Sadece getMessage taşımak da stack trace'i kaybettirir.$e$, 8),

('java-009',
$q$Bir sosyal medya uygulamasında yaklaşık 200 bin öğeden oluşan bir akış listesi bellekte tutuluyor. Liste sayfalama sırasında sıkça get(i) ile okunuyor ve baştan sona dolaşılıyor. Seyrek de olsa ortadan remove(index) ile öğe siliniyor. Bir ekip arkadaşınız, ortadan silme işlemi nedeniyle ArrayList yerine LinkedList kullanılmasını öneriyor. Bu öneriyle ilgili en doğru değerlendirme hangisidir?$q$,
'',
$e$ArrayList'te get(i) O(1)'dir ve elemanlar bellekte bitişik durduğu için iteration CPU cache'inden iyi yararlanır. LinkedList'te get(i) O(n)'dir. LinkedList'te remove(index) da önce silinecek node'u bulmak için listeyi O(n) yürür; sabit süreli olan sadece node bulunduktan sonraki bağlantı değişikliğidir. Bu yüzden seyrek ortadan silme için LinkedList'e geçmek beklenen kazancı sağlamaz. ArrayList'in iterator'ı kopya oluşturmaz. LinkedList her eleman için ayrı bir node nesnesi tuttuğu için daha fazla bellek kullanır.$e$, 9),

('java-010',
$q$Aşağıdaki kod çalıştırıldığında konsola ne yazdırılır?$q$,
$code$Integer a = 127, b = 127;
Integer x = 1000;
int y = 1000;
String s1 = "order";
String s2 = new String("order");

System.out.println(a == b);
System.out.println(x == y);
System.out.println(s1 == s2);
System.out.println(s1 == s2.intern());$code$,
$e$Java dil spesifikasyonu, -128 ile 127 arasındaki değerlerin autoboxing'de aynı nesneye dönüşmesini garanti eder; bu yüzden a == b her JVM'de true'dur. x == y karşılaştırmasında taraflardan biri primitive int olduğu için x unboxing'e uğrar ve iki int değeri karşılaştırılır; 1000 cache aralığının dışında olsa da sonuç true'dur. s2, new ile oluşturulduğu için literal'dan farklı bir nesnedir ve s1 == s2 false'tur. s2.intern() ise String Pool'daki kanonik "order" nesnesini döndürür; s1 de aynı literal'ı gösterdiği için sonuç true'dur. İki Integer nesnesinin 127'den büyük değerlerde == ile karşılaştırılması ise spesifikasyon tarafından garanti edilmez: HotSpot'un varsayılan ayarlarında genellikle false çıkar, ama cache aralığı -XX:AutoBoxCacheMax ile genişletilebilir. Bu yüzden wrapper tiplerde ve String'lerde içerik karşılaştırması için equals kullanılmalıdır.$e$, 10),

('java-011',
$q$Bir ekip, değiştirilemez bir veri taşıyıcısı olarak aşağıdaki record'u tanımladı. Ardından kodun bir bölümünde record'u oluşturan liste ve record'un döndürdüğü liste üzerinden ekleme yapılıyor. Bu kod çalıştırıldığında ne olur?$q$,
$code$public record Team(String name, List<String> members) {}

List<String> list = new ArrayList<>(List.of("Ali"));
Team team = new Team("core", list);

list.add("Ayşe");
team.members().add("Mehmet");

System.out.println(team.members());$code$,
$e$Record'un alanları final'dır, ancak bu sadece referansın yeniden atanmasını engeller. Record otomatik olarak defensive copy yapmaz; members alanı dışarıdan verilen ArrayList'in kendisini gösterir. Bu yüzden iki ekleme de aynı listeye yapılır ve çıktı [Ali, Ayşe, Mehmet] olur. Gerçek immutability için compact constructor'da members = List.copyOf(members) yazılmalıdır; bu hem dışarıdaki listeyle bağı keser hem de değiştirilemez bir liste döner. Record bileşenleri mutable tiplerde tanımlanabilir, bu bir derleme hatası değildir.$e$, 11),

('java-012',
$q$Bir fiyatlandırma servisi, bir indirim kampanyasının etkisini görmek için sepetin kopyasını oluşturuyor ve indirimi bu kopya üzerinde deniyor. Cart sınıfı Cloneable'ı uyguluyor ve clone() metodunda super.clone() çağırıyor. İndirim kopyadaki ürünlere uygulandıktan sonra, orijinal sepetteki fiyatların da değiştiği görülüyor. Bunun en doğru açıklaması ve çözümü hangisidir?$q$,
$code$public class Cart implements Cloneable {
    private List<CartItem> items = new ArrayList<>(); // CartItem'ın setPrice metodu var

    @Override
    public Cart clone() throws CloneNotSupportedException {
        return (Cart) super.clone();
    }
}$code$,
$e$Object.clone() sığ (shallow) kopya yapar: Cart nesnesi kopyalanır, ama items alanına sadece aynı listenin referansı atanır. İki sepet aynı listeyi ve aynı CartItem nesnelerini paylaşır. Çözüm iki katmanlıdır: liste her durumda ayrıca kopyalanmalıdır; CartItem mutable olduğu için elemanlar da kopyalanmalıdır, örneğin copy.items = items.stream().map(CartItem::copy).collect(Collectors.toCollection(ArrayList::new)). CartItem immutable olsaydı yeni bir liste oluşturup aynı elemanları paylaşmak yeterli olurdu; ama liste kopyalanmadan sadece CartItem'ı immutable yapmak yetmez, çünkü indirimli bir elemanı listeye koymak (items.set) ortak listeyi ve dolayısıyla orijinal sepeti değiştirir. Alanı final yapmak paylaşımı engellemez. CopyOnWriteArrayList de çözüm değildir: iki sepet aynı liste nesnesini tuttuğu sürece birinin yaptığı değişiklik diğerinde görünür; bu sınıf sadece devam eden iteration'ları değişikliklerden korur. CartItem'a Cloneable eklemek de tek başına yetmez, çünkü super.clone() elemanları kendiliğinden kopyalamaz.$e$, 12),

('java-001b',
$q$Bir kullanıcı kayıt servisi, e-posta adreslerini kaydetmeden önce aşağıdaki metotla normalize ediyor. Buna rağmen veritabanında aynı adresin "Ali@Mail.com " ve "ali@mail.com" gibi farklı yazımlarla birden fazla kez kayıtlı olduğu görülüyor. Bunun nedeni nedir?$q$,
$code$void register(String email) {
    email.trim();
    email.toLowerCase();
    if (!userRepository.existsByEmail(email)) {
        userRepository.save(new User(email));
    }
}$code$,
$e$String immutable'dır. trim ve toLowerCase mevcut nesneyi değiştirmez, her biri yeni bir String döndürür. Dönen değerler bir değişkene atanmadığı için kaybolur ve kontrol de kayıt da orijinal değerle yapılır. Doğrusu email = email.trim().toLowerCase(Locale.ROOT) yazmaktır; Locale verilmezse Türkçe gibi dillerde "I" harfi beklenmedik şekilde dönüşebilir. trim de yerinde değişiklik yapmaz. JIT, sonucu kullanılmayan bir çağrıyı atlasa bile bu programın anlamını değiştirmez; çağrıları zincirlemek de sonuç atanmadıkça hiçbir şeyi düzeltmez. intern() sadece String Pool'daki kanonik nesneyi döndürür ve dönüşümleri kalıcı yapmaz. Immutability'nin avantajı da burada görülür: bu metoda verilen String, çağıranın elindeki değeri yanlışlıkla değiştiremez.$e$, 1),

('java-002b',
$q$Bir kullanıcı profili cache'i başlangıçta HashMap ile yazılmıştı. Veritabanında bulunamayan kullanıcılar için tekrar tekrar sorgu atılmasın diye cache'e null değeri konuyordu. Yük altında tutarsızlıklar görülünce ekip map'i ConcurrentHashMap ile değiştirdi. Bu kez bulunamayan bir kullanıcı sorgulandığında NullPointerException alınıyor. Bunun nedeni ve doğru düzeltme hangisidir?$q$,
$code$private final Map<Long, Profile> cache = new ConcurrentHashMap<>();

Profile find(long userId) {
    if (cache.containsKey(userId)) {
        return cache.get(userId);
    }
    Profile profile = repository.findById(userId).orElse(null);
    cache.put(userId, profile);
    return profile;
}$code$,
$e$ConcurrentHashMap ne null key ne de null value kabul eder; put(userId, null) NullPointerException fırlatır. Bu bilinçli bir tasarımdır: eşzamanlı bir ortamda get null döndüğünde "key yok" ile "değer null" ayrımı ancak ikinci bir çağrıyla (containsKey) yapılabilir ve iki çağrı arasında map değişebilir. Bulunamayan kayıtları da cache'lemek için null olmayan bir değer gerekir: cache tipi Map<Long, Optional<Profile>> yapılır ve bulunamayan kayıt Optional.empty() ile temsil edilir. Okuma cache.computeIfAbsent(userId, repository::findById) ile tek adımda yapılır; bu, koddaki containsKey + get yarışını da ortadan kaldırır. Dikkat: computeIfAbsent'e verilen fonksiyon null döndürürse map'e hiçbir kayıt eklenmez. Bu yüzden fonksiyondan findById(id).orElse(null) döndürmek negatif cache oluşturmaz ve her çağrı yine veritabanına gider. Hata boxing'den gelmez: primitive long, Long'a dönüştürülürken null olamaz. Başlangıç kapasitesinin bu hatayla ilgisi yoktur.$e$, 2),

('java-003b',
$q$Bir ekip arkadaşınız, aşağıdaki metodun veritabanı hatasında çağırana bir exception ileteceğini ve catch bloğunun çalışacağını düşünüyor. Kod çalıştırıldığında konsola ne yazdırılır?$q$,
$code$static int attempts = 0;

static int sync() {
    try {
        attempts++;
        throw new IllegalStateException("db down");
    } finally {
        return attempts;
    }
}

try {
    System.out.println(sync());
} catch (IllegalStateException e) {
    System.out.println("error: " + e.getMessage());
}$code$,
$e$finally bloğundan return yapmak, try bloğunda fırlatılan exception'ı tamamen yok eder. Metot normal şekilde 1 döndürür ve çağırandaki catch bloğu hiç çalışmaz. Kod derlenir; derleyici en fazla "finally block does not complete normally" uyarısı verir. finally içinden return, break veya continue kullanmak hataları sessizce yuttuğu için yapılmamalıdır. finally'nin asıl amacı kaynak temizliğidir ve bu iş için de bugün try-with-resources tercih edilir.$e$, 3),

('java-004b',
$q$Bir eklenti (plugin) sistemi, eklentilerin metotlarını isimleriyle reflection kullanarak çağırıyor. Bir eklenti, iş kuralı ihlalinde InvalidOrderException fırlatıyor; bu sınıf RuntimeException'dan türüyor. Çağıran kod bu hatayı yakalayıp kullanıcıya anlamlı bir mesaj göstermek istiyor, ancak ilgili catch bloğu hiç çalışmıyor ve hata log'a "Plugin call failed" olarak düşüyor. Bunun nedeni nedir?$q$,
$code$try {
    Method method = plugin.getClass().getMethod(action, Order.class);
    method.invoke(plugin, order);
} catch (InvalidOrderException e) {
    showWarning(e.getMessage());
} catch (ReflectiveOperationException e) {
    log.error("Plugin call failed", e);
}$code$,
$e$Method.invoke, çağrılan metodun fırlattığı her exception'ı, checked veya unchecked fark etmeksizin InvocationTargetException içine sarar. InvocationTargetException bir ReflectiveOperationException olduğu için ikinci catch bloğuna düşer. Asıl exception getCause() ile alınır ve gerekiyorsa yeniden fırlatılır. UndeclaredThrowableException ayrı bir mekanizmadır: dinamik proxy'lerin, metot imzasında bildirilmemiş checked exception'ları sarmak için kullandığı bir tiptir. setAccessible sadece erişim kontrolünü kaldırır ve exception davranışını değiştirmez. getMethod, üst sınıflardan gelenler dahil public metotları bulabilir.$e$, 4),

('java-005b',
$q$Bir raporlama servisinde tarihleri biçimlendirmek için aşağıdaki yardımcı sınıf kullanılıyor. Formatter her çağrıda yeniden oluşturulmasın diye static bir alanda tutuluyor. Testlerde sorun çıkmıyor; ancak production'da yoğun saatlerde bazı raporlarda tarihlerin karıştığı, parse sırasında da zaman zaman beklenmedik exception'lar alındığı görülüyor. En doğru açıklama ve çözüm hangisidir?$q$,
$code$public final class DateUtils {
    private static final SimpleDateFormat FORMAT =
            new SimpleDateFormat("yyyy-MM-dd HH:mm");

    public static String format(Date date) {
        return FORMAT.format(date);
    }

    public static Date parse(String text) throws ParseException {
        return FORMAT.parse(text);
    }
}$code$,
$e$Static alan instance'a değil sınıfa aittir; FORMAT nesnesi tüm request thread'leri arasında tek bir instance olarak paylaşılır. SimpleDateFormat thread-safe değildir: biçimlendirme ve parse sırasında içindeki Calendar nesnesinin state'ini değiştirir. Aynı anda çalışan iki thread birbirinin ara state'ini ezer; bu da yanlış tarihlere veya parse sırasında rastgele exception'lara yol açar. Testlerde görülmemesinin nedeni, testlerin genellikle tek thread'de çalışmasıdır. Alanın final olması sadece referansın değişmesini engeller, nesnenin iç state'ini korumaz; volatile de sadece referansın görünürlüğünü etkiler. Çözüm, immutable ve thread-safe olan java.time.DateTimeFormatter'a geçmektir; bu nesne static bir alanda güvenle paylaşılabilir. Eski API zorunluysa her çağrıda yeni bir SimpleDateFormat oluşturmak veya ThreadLocal kullanmak alternatiflerdir; metotları synchronized yapmak doğru sonuç verir ama tüm çağrıları sıraya sokar. Static alanlar thread başına kopyalanmaz ve sınıf her istekte yeniden yüklenmez.$e$, 5),

('java-006b',
$q$Bir kampanya servisinde kullanılabilir kuponlar HashSet<Coupon> içinde tutuluyor. Coupon'ın equals ve hashCode metotları code alanına göre yazılmış. Bir yönetici kuponun kodunu düzelttikten sonra aşağıdaki davranış görülüyor. Bunun nedeni nedir?$q$,
$code$Set<Coupon> active = new HashSet<>();
Coupon coupon = new Coupon("SUMMER10");
active.add(coupon);

coupon.setCode("SUMMER-10");

active.contains(coupon); // false
active.remove(coupon);   // false
active.add(coupon);      // true: set'te artık aynı nesneden iki kayıt var$code$,
$e$HashSet içeride bir HashMap kullanır ve elemanı eklendiği andaki hashCode değerine göre bir bucket'a yerleştirir. code değişince hashCode da değişir; contains ve remove yeni hash ile başka bir bucket'a bakar ve elemanı bulamaz. Eleman ise eski bucket'ta kalmaya devam eder, bu yüzden aynı nesne ikinci kez eklenebilir. hashCode veya equals'a katılan alanlar, nesne hash tabanlı bir koleksiyondayken değiştirilmemelidir; en iyisi bu alanları immutable yapmaktır. HashSet resize sırasında kayıt kaybetmez ve elemanların Comparable olması gerekmez.$e$, 6),

('java-007b',
$q$Bir kategori servisi, ürün kategorilerini aşağıdaki recursive metotla dolaşıyor. Yanlış girilen bir veri yüzünden iki kategori birbirini üst kategori olarak gösterince servis StackOverflowError ile çöküyor. Ekip, belleğin yetmediğini düşünerek -Xmx değerini 2 GB'tan 8 GB'a çıkarıyor, ama hata aynen devam ediyor. En doğru açıklama hangisidir?$q$,
$code$int depth(Category category) {
    if (category.getParent() == null) {
        return 0;
    }
    return 1 + depth(category.getParent());
}$code$,
$e$Her metot çağrısı, çalışan thread'in stack'ine yeni bir frame ekler. Döngüsel veri yüzünden recursion hiç bitmez ve thread'in stack'i dolar. -Xmx heap'in boyutunu belirler; thread stack'inin boyutu ise -Xss ile ayrıca belirlenir. Bu yüzden heap'i büyütmek bu hatayı çözmez. -Xss'i artırmak da sadece hatayı geciktirir. Asıl çözüm, döngüyü tespit etmek (ziyaret edilen kategorileri bir Set'te tutmak), bir derinlik sınırı koymak veya algoritmayı iteratif hale getirmektir. Stack frame'leri heap'te tutulmaz ve GC algoritmasını değiştirmek stack'i etkilemez.$e$, 7),

('java-008b',
$q$Bir dosya içe aktarma işi her satırı ayrı ayrı işliyor ve hatalı satırlar yüzünden tüm iş durmasın diye döngünün içinde catch (Exception e) kullanıyor. Çok büyük bir dosyada iş, hiçbir satır uyarısı loglamadan sonlanıyor; incelemede OutOfMemoryError oluştuğu görülüyor. Ekipten biri, işin dayanıklı olması için catch bloğunu catch (Throwable t) yapmayı ve hatadan sonra devam etmeyi öneriyor. Bu öneriyle ilgili en doğru değerlendirme hangisidir?$q$,
$code$for (String line : Files.readAllLines(path)) {
    try {
        importRow(parse(line));
    } catch (Exception e) {
        log.warn("Row skipped: {}", line, e);
    }
}$code$,
$e$OutOfMemoryError, Exception'ın değil Error'ın alt sınıfıdır; bu yüzden catch (Exception) onu yakalamaz. Error türleri JVM seviyesindeki ciddi durumları temsil eder. Throwable yakalayıp devam etmek, JVM'i tutarsız olabilecek bir durumda çalıştırmaya devam etmek demektir; OOM sırasında başka thread'lerde de rastgele hatalar oluşabilir. Asıl sorun tasarımdadır: Files.readAllLines tüm dosyayı belleğe alır. Files.lines veya BufferedReader ile satır satır okumak bellek kullanımını sabit tutar. System.gc() de çözüm değildir: sadece bir istektir ve JVM, bellek ayırabilmek için gereken GC çalışmalarını zaten kendisi yapar. Asıl sorun tüm dosyanın belleğe alınmasıdır.$e$, 8),

('java-009b',
$q$Bir bildirim servisi, gönderilecek mesajları bir ArrayList içinde biriktiriyor ve ayrı bir iş, listeyi en eski mesajdan başlayarak aşağıdaki gibi işliyor. Liste birkaç bin elemanken sorun yok; ancak kampanya dönemlerinde liste 500 bin mesaja ulaşınca işleme süresi dakikalardan saatlere çıkıyor. En doğru açıklama ve çözüm hangisidir?$q$,
$code$List<Notification> pending = new ArrayList<>(loadPending());

while (!pending.isEmpty()) {
    Notification next = pending.remove(0);
    send(next);
}$code$,
$e$ArrayList dizi tabanlıdır. remove(0), ilk elemanı çıkardıktan sonra kalan tüm elemanları bir sola kaydırır ve bu işlem O(n)'dir. Döngü n kez çalıştığı için toplam maliyet karesel büyür. Mesajlar baştan sırayla tüketiliyorsa doğru yapı bir kuyruktur: ArrayDeque ile poll() baştan çıkarmayı O(1) yapar ve LinkedList'ten daha az bellek kullanır. ArrayList'te iterator.remove() da aynı kaydırmayı yapar. trimToSize sadece fazla kapasiteyi serbest bırakır, kaydırmayı engellemez. Sondan çıkarmak O(1)'dir ama mesajları ters sırada işler.$e$, 9),

('java-010b',
$q$Bir ödeme servisinde Money sınıfı aşağıdaki gibi tanımlanmış. Testlerde iki Money nesnesi doğrudan equals ile karşılaştırıldığında sonuç doğru çıkıyor, ancak aynı değer bir liste içinde arandığında bulunamıyor. Bunun nedeni nedir?$q$,
$code$public final class Money {
    private final long amount;
    private final String currency;

    // constructor ...

    public boolean equals(Money other) {
        return other != null
            && amount == other.amount
            && currency.equals(other.currency);
    }

    @Override
    public int hashCode() {
        return Objects.hash(amount, currency);
    }
}

Money a = new Money(100, "TRY");
Money b = new Money(100, "TRY");

a.equals(b);             // true
List.of(a).contains(b);  // false$code$,
$e$equals(Money other) metodu Object.equals(Object) metodunu override etmez, aynı isimde yeni bir overload tanımlar. a.equals(b) çağrısında derleyici, argümanın statik tipi Money olduğu için bu overload'u seçer ve sonuç true olur. List.contains ise elemanları Object olarak karşılaştırır ve Object.equals(Object) çağırır; bu metot override edilmediği için referans karşılaştırması yapılır ve sonuç false olur. Doğrusu equals(Object o) imzasıyla yazmak ve üzerine @Override eklemektir; @Override olsaydı bu hata derleme aşamasında yakalanırdı. List.contains hashCode kullanmaz ve sınıfın final olması metot seçimini değiştirmez.$e$, 10),

('java-011b',
$q$Bir yetkilendirme modülünde kullanıcı rolleri aşağıdaki sınıfla tutuluyor. Geliştirici, constructor'da listeyi Collections.unmodifiableList ile sardığı için sınıfın değiştirilemez olduğunu düşünüyor. Ancak bir güvenlik testinde, nesne oluşturulduktan sonra kullanıcının ADMIN rolü kazandığı görülüyor. Bunun nedeni ve doğru düzeltme hangisidir?$q$,
$code$public final class Permissions {
    private final List<String> roles;

    public Permissions(List<String> roles) {
        this.roles = Collections.unmodifiableList(roles);
    }

    public boolean has(String role) {
        return roles.contains(role);
    }
}

List<String> roles = new ArrayList<>(List.of("USER"));
Permissions permissions = new Permissions(roles);
roles.add("ADMIN");

permissions.has("ADMIN"); // true$code$,
$e$Collections.unmodifiableList kopya oluşturmaz; alttaki listeye salt okunur bir görünüm (view) döndürür. Bu görünüm üzerinden değişiklik yapılamaz, ama alttaki liste değişirse görünüm de değişir. Constructor'a liste veren kod, elindeki referansla listeyi değiştirebildiği için Permissions nesnesinin state'i de değişir. Doğrusu constructor'da List.copyOf(roles) ile kopya almaktır; List.copyOf hem dışarıdaki listeyle bağı keser hem de değiştirilemez bir liste döner. Alanın final olması sadece referansın yeniden atanmasını engeller; tipin List ya da Set olması bunu değiştirmez. Kodda reflection kullanılmamıştır ve has metodunda bir eşzamanlılık sorunu yoktur.$e$, 11),

('java-012b',
$q$Bir faturalama sistemi, taslak bir faturanın bağımsız bir kopyası üzerinde düzenleme yapabilmek için aşağıdaki copy constructor'ı kullanıyor. Performans incelemesinde bu constructor'ın gereksiz yere çok fazla nesne oluşturduğu görülüyor. Kopyanın orijinalden tamamen bağımsız olması için hangi alanların gerçekten kopyalanması gerekir?$q$,
$code$public class Invoice {
    private String number;
    private LocalDate issueDate;
    private BigDecimal total;
    private Customer customer;        // record Customer(String name, String taxId)
    private List<InvoiceLine> lines;  // InvoiceLine'ın setQuantity metodu var

    public Invoice(Invoice other) {
        this.number = new String(other.number);
        this.issueDate = LocalDate.of(other.issueDate.getYear(),
                other.issueDate.getMonth(), other.issueDate.getDayOfMonth());
        this.total = new BigDecimal(other.total.toString());
        this.customer = new Customer(other.customer.name(), other.customer.taxId());
        this.lines = other.lines.stream()
                .map(InvoiceLine::copy)
                .collect(Collectors.toCollection(ArrayList::new));
    }
}$code$,
$e$Deep copy her alan için gerekli değildir. String, LocalDate ve BigDecimal immutable'dır; hiçbiri yerinde değiştirilemediği için iki nesne arasında güvenle paylaşılabilir. Bu senaryodaki Customer record'unun bileşenleri de immutable String'ler olduğu için aynı instance paylaşılabilir. Ancak record olmak tek başına deep immutability garantisi değildir: record bir List gibi mutable bir bileşen içerseydi, o bileşenin de ayrıca ele alınması gerekirdi. Kopyada bu alanlara yeni bir değer atamak orijinali etkilemez. Bağımsızlık için sadece değişebilen yapıların kopyalanması gerekir: lines listesi ve listedeki mutable InvoiceLine nesneleri. Sadece listeyi kopyalamak yetmez, çünkü setQuantity iki faturanın paylaştığı aynı InvoiceLine nesnesini değiştirir. Record'un alanları final'dır ve accessor metotları sadece değeri döndürür, değiştirmez.$e$, 12);

CREATE TEMP TABLE java_options (
    question_id varchar(50) NOT NULL REFERENCES java_questions(id),
    text text NOT NULL,
    is_correct boolean NOT NULL,
    sort_order integer NOT NULL,
    PRIMARY KEY (question_id, sort_order)
) ON COMMIT DROP;

INSERT INTO java_options VALUES

('java-001', $o$StringBuffer kullanılmalıdır; servis çok thread'li çalıştığı için metodun içindeki builder nesnesine de aynı anda birden fazla thread erişebilir.$o$, false, 0),
('java-001', $o$String ile + kullanılmalıdır; Java 9 ve sonrasında derleyici döngüdeki birleştirmeleri de tek bir buffer üzerinde topladığı için ek nesne oluşmaz.$o$, false, 1),
('java-001', $o$StringBuilder yeterlidir; builder metodun yerel değişkeni olduğu için her çağrı kendi nesnesini kullanır ve nesne thread'ler arasında paylaşılmaz.$o$, true, 2),
('java-001', $o$StringBuilder kalabilir, ancak metot synchronized yapılmalıdır; aksi halde farklı thread'lerin ürettiği mesajlar aynı buffer içinde birbirine karışabilir.$o$, false, 3),

('java-002', $o$getOrDefault ve put ayrı ayrı atomiktir, ama aralarında başka bir thread araya girebilir; artış merge(endpoint, 1, Integer::sum) ile tek adımda yapılmalıdır.$o$, true, 0),
('java-002', $o$ConcurrentHashMap okumalarda kilit kullanmadığı için getOrDefault eski bir değer görebilir; okuma ve yazma birlikte synchronized bir blokla sarılmalıdır.$o$, false, 1),
('java-002', $o$Integer immutable olduğu için her artışta yeni bir nesne oluşur ve önceki değer kaybolur; değer tipi AtomicInteger yapılırsa put ile yazmak yeterli olur.$o$, false, 2),
('java-002', $o$ConcurrentHashMap aynı segmentteki key'leri tek kilitle koruduğu için yoğun endpoint'ler birbirini ezer; concurrencyLevel parametresi artırılmalıdır.$o$, false, 3),

('java-003', $o$İki iddia da doğrudur; final alan listenin içeriğini de korur ve finalize, nesne toplanmadan önce çalıştığı için dosyanın kapatılmasını güvence altına alır.$o$, false, 0),
('java-003', $o$İlk iddia yanlış, ikincisi doğrudur; final sadece referansı korur, finalize ise Java 18'den beri her nesne için en az bir kez çalıştırılacak şekilde güncellenmiştir.$o$, false, 1),
('java-003', $o$İki iddia da yanlıştır; dosya kapatma işi finally bloğuna taşınmalıdır, çünkü finally bloğu System.exit çağrılsa bile JVM kapanmadan önce çalıştırılır.$o$, false, 2),
('java-003', $o$İki iddia da yanlıştır; final sadece referansı korur, finalize'ın ne zaman çalışacağı belli değildir ve dosya try-with-resources ile kapatılmalıdır.$o$, true, 3),

('java-004', $o$getDeclaredFields private alanları listelemez; annotation private bir alana konduğu için döngü bu alana hiç ulaşmaz ve getFields kullanılmalıdır.$o$, false, 0),
('java-004', $o$Retention belirtilmediği için varsayılan CLASS politikası geçerlidir; annotation class dosyasında bulunur ama runtime'da reflection ile okunamaz.$o$, true, 1),
('java-004', $o$Private alanların annotation'larını okumadan önce setAccessible(true) çağrılması gerekir; bu çağrı yapılmadığı için isAnnotationPresent false döner.$o$, false, 2),
('java-004', $o$Annotation'lar derleme sırasında işlendiği için runtime'da okunabilmeleri adına projeye ayrıca bir annotation processor eklenmesi gerekir.$o$, false, 3),

('java-005', $o$Static alanlar GC root olduğu için cache'teki Row nesneleri toplanamaz; ancak Row'lar ReportGenerator'a bağlı olmadığı için sorun yalnızca Row nesnelerinin kendisidir.$o$, false, 0),
('java-005', $o$Her ReportGenerator için Row sınıfı ayrıca yüklendiği için Metaspace dolar; heap dump bu sınıf metadata'sını ReportGenerator nesneleri olarak gösterir.$o$, false, 1),
('java-005', $o$Static olmayan inner class her Row nesnesinde dış ReportGenerator nesnesine gizli bir referans tutar; cache'teki Row'lar onu da canlı tutar.$o$, true, 2),
('java-005', $o$Static map thread'ler arasında paylaşıldığı için JVM her thread için ayrı bir kopyasını tutar; bu kopyalar ReportGenerator nesnelerini bellekte bırakır.$o$, false, 3),

('java-006', $o$hashCode override edilmediği için eşit iki nesne genellikle farklı hash üretir ve get farklı bir bucket'a bakar; hashCode da aynı alanlarla yazılmalıdır.$o$, true, 0),
('java-006', $o$HashMap equals'ı yalnızca aynı referansa sahip key'ler için çağırır; bu yüzden aynı ProductKey nesnesinin saklanıp sorgularda tekrar kullanılması gerekir.$o$, false, 1),
('java-006', $o$HashMap key'leri compareTo ile karşılaştırır; ProductKey Comparable arayüzünü uygulamadığı için eşleşme bulunamaz ve sorgu null döner.$o$, false, 2),
('java-006', $o$equals içinde String alanlar == ile karşılaştırılmış olabilir; equals Objects.equals ile yazılırsa hashCode olmadan da get doğru değeri bulur.$o$, false, 3),

('java-007', $o$retries ve order değişkenleri stack'te, Order nesnesi heap'tedir; metot bittiğinde Order nesnesi de stack frame ile birlikte bellekten kaldırılır.$o$, false, 0),
('java-007', $o$retries ve order referansı stack'tedir; Order nesnesi heap'te olsa da içindeki attempts alanı primitive olduğu için stack'te tutulur.$o$, false, 1),
('java-007', $o$Order nesnesi new ile oluşturulduğu için heap'tedir; retries ise metot boyunca değişmediği için JIT tarafından heap'teki constant pool'a taşınır.$o$, false, 2),
('java-007', $o$Kavramsal olarak retries ve order referansı stack frame'dedir; Order nesnesi ve attempts alanı heap'tedir, queue onu tuttukça GC toplamaz.$o$, true, 3),

('java-008', $o$catch bloğuna e.printStackTrace() eklenmelidir; böylece kök neden konsola yazılır ve merkezi handler'daki tekrar eden log kaldırılabilir.$o$, false, 0),
('java-008', $o$PaymentException orijinal hata cause olarak verilerek oluşturulmalı ve hata, son ele alındığı tek bir yerde loglanmalıdır.$o$, true, 1),
('java-008', $o$PaymentException checked exception yapılmalıdır; böylece compiler her çağıranın hatayı ele almasını zorunlu kılar ve kök neden kaybolmaz.$o$, false, 2),
('java-008', $o$IOException yerine catch (Exception e) kullanılmalı ve yeni exception'a e.getMessage() taşınmalıdır; böylece tüm hatalar tek mesajda toplanır.$o$, false, 3),

('java-009', $o$ArrayList kalmalıdır; index erişimi ve dolaşmada üstündür, LinkedList'te de remove(index) önce node'u bulmak için listeyi baştan dolaşır.$o$, true, 0),
('java-009', $o$LinkedList'e geçilmelidir; remove(index) sabit sürede çalışır ve sayfalamadaki get(i) maliyeti iterator kullanıldığında ArrayList ile aynı seviyeye iner.$o$, false, 1),
('java-009', $o$ArrayList kalmalıdır, ancak dolaşma için for-each yerine index'li döngü kullanılmalıdır; ArrayList'in iterator'ı her adımda listenin bir kopyasını oluşturur.$o$, false, 2),
('java-009', $o$LinkedList'e geçilmelidir; elemanlar ayrı node'larda tutulduğu için bellek kullanımı daha düşüktür ve dolaşma sırasında CPU cache'i daha verimli kullanılır.$o$, false, 3),

('java-010', $o$true / false / false / true$o$, false, 0),
('java-010', $o$true / true / true / true$o$, false, 1),
('java-010', $o$true / true / false / true$o$, true, 2),
('java-010', $o$true / false / true / true$o$, false, 3),

('java-011', $o$Record alanları final olduğu için iki ekleme de UnsupportedOperationException fırlatır ve team nesnesinin listesi hiç değişmez.$o$, false, 0),
('java-011', $o$İki ekleme de başarılı olur ve çıktı [Ali, Ayşe, Mehmet] olur; record listeyi kendiliğinden kopyalamaz, kopya ayrıca alınmalıdır.$o$, true, 1),
('java-011', $o$Record oluşturulurken listenin bir kopyası alındığı için ilk ekleme team'i etkilemez; ikinci ekleme kopyaya yapılır ve çıktı [Ali, Mehmet] olur.$o$, false, 2),
('java-011', $o$Kod derlenmez; record bileşenleri List gibi mutable tiplerde tanımlanamaz, bunun yerine dizi ya da değiştirilemez bir koleksiyon tipi kullanılmalıdır.$o$, false, 3),

('java-012', $o$clone() derin kopya yapar, ancak CartItem Cloneable uygulamadığı için kopyalanamamıştır; CartItem sınıfına Cloneable eklemek sorunu çözer.$o$, false, 0),
('java-012', $o$items alanı final yapılmalıdır; final bir alan kopyalar arasında paylaşılamadığı için clone her sepete ayrı bir liste atar.$o$, false, 1),
('java-012', $o$Sorun clone'dan değil liste tipinden kaynaklanır; ArrayList yerine CopyOnWriteArrayList kullanılırsa kopya ve orijinal birbirini etkilemez.$o$, false, 2),
('java-012', $o$super.clone() sığ kopya yapar ve liste paylaşılır; kopya için yeni liste oluşturulmalı, mutable CartItem'lar da kopyalanmalıdır.$o$, true, 3),

('java-001b', $o$String immutable olduğu için trim ve toLowerCase yeni nesne döndürür; sonuç email'e atanmadığından kayıt orijinal haliyle yapılır.$o$, true, 0),
('java-001b', $o$trim nesneyi yerinde değiştirir ama toLowerCase yeni bir nesne döndürür; sadece ikinci çağrının sonucu email değişkenine atanmalıdır.$o$, false, 1),
('java-001b', $o$JIT, sonucu kullanılmayan metot çağrılarını atlar; iki çağrı tek bir zincirde yazılırsa JIT onları atlayamaz ve dönüşümler uygulanır.$o$, false, 2),
('java-001b', $o$email bir literal'dan gelmediği için String Pool'da değildir; dönüşümlerin kalıcı olması için önce email.intern() çağrılmalıdır.$o$, false, 3),

('java-002b', $o$long key Long'a dönüştürülürken boxing sırasında null değer üretebilir; metot parametresi Long yapılarak dönüşüm ortadan kaldırılmalıdır.$o$, false, 0),
('java-002b', $o$Başlangıç kapasitesi verilmediğinde ilk put sırasında iç tablo henüz oluşmamış olabilir; ConcurrentHashMap'e kapasite verilmelidir.$o$, false, 1),
('java-002b', $o$ConcurrentHashMap null key'i reddeder ama null değeri kabul eder; hata containsKey'den gelir, yerine get(userId) != null kullanılmalıdır.$o$, false, 2),
('java-002b', $o$ConcurrentHashMap null değer almaz; cache tipi Map<Long, Optional<Profile>> yapılıp bulunamayan kayıt Optional.empty() ile tutulmalı.$o$, true, 3),

('java-003b', $o$error: db down$o$, false, 0),
('java-003b', $o$1$o$, true, 1),
('java-003b', $o$1 ve ardından error: db down$o$, false, 2),
('java-003b', $o$Kod derlenmez$o$, false, 3),

('java-004b', $o$Reflection ile çağrılan metotların unchecked exception'ları UndeclaredThrowableException ile sarılır; catch bu tipi yakalamalıdır.$o$, false, 0),
('java-004b', $o$getMethod sadece sınıfın kendi tanımladığı metotları bulur; metot üst sınıftan geliyorsa çağrı NoSuchMethodException ile düşer.$o$, false, 1),
('java-004b', $o$invoke, çağrılan metodun fırlattığı her exception'ı InvocationTargetException içine sarar; asıl hata getCause() ile alınmalıdır.$o$, true, 2),
('java-004b', $o$setAccessible(true) çağrılmadığı için JVM asıl exception'ı güvenlik nedeniyle gizler; erişim açılırsa exception doğrudan iletilir.$o$, false, 3),

('java-005b', $o$Static alanlar her thread için ayrı bir kopya olarak tutulur; kopyalar senkronize edilmediği için thread'ler farklı ayarlarla biçimlendirme yapar.$o$, false, 0),
('java-005b', $o$FORMAT final olduğu için JVM onu CPU cache'inde tutar; alan volatile yapılırsa tüm thread'ler formatter'ın güncel halini görür ve sorun çözülür.$o$, false, 1),
('java-005b', $o$Static alanlar sınıf yüklenirken initialize edilir; yoğun saatlerde sınıf yeniden yüklendiği için formatter yarım kalmış bir pattern ile çalışır.$o$, false, 2),
('java-005b', $o$FORMAT tüm thread'lerin paylaştığı tek bir nesnedir ve SimpleDateFormat thread-safe değildir; immutable DateTimeFormatter kullanılmalıdır.$o$, true, 3),

('java-006b', $o$HashSet elemanları sadece equals ile karşılaştırır; equals'ta getClass yerine instanceof kullanıldığı için kodu değişen kupon eşleşmez.$o$, false, 0),
('java-006b', $o$Eleman, eklendiği andaki hash değerine göre bir bucket'a konmuştur; code değişince aramalar başka bucket'a bakar ve elemanı bulamaz.$o$, true, 1),
('java-006b', $o$Kupon eklendikten sonra set resize olduğunda eski hash değerleri silinir; set'e baştan yeterli kapasite verilirse sorun ortadan kalkar.$o$, false, 2),
('java-006b', $o$Coupon Comparable olmadığı için HashSet onu ağaç yapısına taşıyamaz; kodu değişen eleman ağaçtaki konumunu kaybeder ve bulunamaz.$o$, false, 3),

('java-007b', $o$Stack frame'leri heap üzerinde tutulduğu için 8 GB yetmemiştir; -Xmx daha da artırılmalı ve Category nesneleri küçültülmelidir.$o$, false, 0),
('java-007b', $o$GC recursion sırasında thread'i durduramadığı için frame'leri temizleyemez; ZGC gibi eşzamanlı çalışan bir GC'ye geçilirse sorun çözülür.$o$, false, 1),
('java-007b', $o$Her çağrı thread stack'ine bir frame ekler ve döngü bu stack'i doldurur; -Xmx stack'i değil heap'i büyütür, döngü tespit edilmelidir.$o$, true, 2),
('java-007b', $o$Kategoriler birbirine referans verdiği için GC onları toplayamaz; heap'te biriken bu nesneler sonunda stack'e taşar ve hata buradan doğar.$o$, false, 3),

('java-008b', $o$Öneri yanlıştır; OOM bir Error'dır ve yakalayıp devam etmek JVM'i belirsiz bir durumda bırakır. Dosya satır satır, akış olarak okunmalıdır.$o$, true, 0),
('java-008b', $o$Öneri doğrudur; OOM unchecked bir RuntimeException olduğu için Throwable ile yakalanabilir ve sonraki satırlar sorunsuz işlenmeye devam eder.$o$, false, 1),
('java-008b', $o$Öneri tek başına yetmez; Throwable yakalandıktan sonra System.gc() çağrılarak bellek boşaltılırsa iş kaldığı satırdan güvenle devam eder.$o$, false, 2),
('java-008b', $o$Öneri gereksizdir; catch (Exception) OOM'u zaten yakalar, ama hata WARN seviyesinde loglandığı için görünmemiştir, ERROR yapılmalıdır.$o$, false, 3),

('java-009b', $o$ArrayList her remove'da kapasitesini küçültüp diziyi yeniden oluşturur; döngüden önce trimToSize() çağrılırsa bu maliyet ortadan kalkar.$o$, false, 0),
('java-009b', $o$remove(0) yerine iterator ile dolaşıp iterator.remove() kullanılmalıdır; iterator silme işleminde elemanları kaydırmadan bağlantıyı günceller.$o$, false, 1),
('java-009b', $o$Liste sondan işlenmelidir; remove(size() - 1) kaydırma gerektirmez ve mesajlar yine geliş sırasına göre gönderilmiş olur.$o$, false, 2),
('java-009b', $o$remove(0) her çağrıda kalan elemanları kaydırır ve toplam maliyet karesel büyür; baştan tüketilen kuyruk için ArrayDeque kullanılmalıdır.$o$, true, 3),

('java-010b', $o$List.contains elemanları önce hashCode ile karşılaştırır; Objects.hash her çağrıda farklı değer üretebildiği için eşleşme bulunamaz.$o$, false, 0),
('java-010b', $o$equals(Money) override değil overload'dur; contains Object.equals(Object) çağırdığı için karşılaştırma referansla yapılır.$o$, true, 1),
('java-010b', $o$List.of değiştirilemez liste döndürür ve elemanları == ile karşılaştırır; ArrayList kullanılırsa contains equals metodunu çağırır.$o$, false, 2),
('java-010b', $o$Sınıf final olduğu için JVM equals çağrısını statik bağlar; final kaldırılırsa contains doğru equals metoduna dinamik olarak ulaşır.$o$, false, 3),

('java-011b', $o$unmodifiableList kopya değil, alttaki listeye bir görünümdür; dışarıdaki liste değişince roller de değişir, kopya alınmalıdır.$o$, true, 0),
('java-011b', $o$final, List gibi koleksiyonların içeriğini sadece Set'lerde korur; roles alanı Set<String> olarak tanımlanırsa içerik de değişmez hale gelir.$o$, false, 1),
('java-011b', $o$unmodifiableList listenin kopyasını alır, ama has metodu senkronize olmadığı için eski kopya ile yeni liste arasında tutarsızlık oluşur.$o$, false, 2),
('java-011b', $o$Test kodu reflection ile roles alanına erişip listeyi değiştirmiştir; final alanlar reflection'a karşı korunmadığı için alan gizlenmelidir.$o$, false, 3),

('java-012b', $o$Tüm alanlar kopyalanmalıdır; String ve BigDecimal referans tipi olduğu için paylaşılırlarsa kopyadaki değişiklik orijinale de yansır.$o$, false, 0),
('java-012b', $o$Sadece lines listesi yeni bir ArrayList'e kopyalanmalıdır; liste ayrılınca içindeki InvoiceLine nesneleri de iki fatura arasında ayrılır.$o$, false, 1),
('java-012b', $o$Sadece lines ve içindeki mutable InvoiceLine'lar kopyalanmalıdır; String, LocalDate, BigDecimal ve Customer immutable olduğu için paylaşılabilir.$o$, true, 2),
('java-012b', $o$lines ve Customer kopyalanmalıdır; record'lar alanlarını final tutsa da accessor metotlarıyla değiştirilebildiği için paylaşılmaları güvenli değildir.$o$, false, 3);

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM questions q
        JOIN java_questions s ON s.id = q.id
        WHERE q.quiz_id IS DISTINCT FROM (SELECT quiz_id FROM java_target)
    ) THEN
        RAISE EXCEPTION 'A Java question ID is already used by another quiz';
    END IF;
END;
$$;

-- Remove questions from the previous version of this quiz that are not part of the new set.
DELETE FROM options o
USING questions q
WHERE o.question_id = q.id
  AND q.quiz_id = (SELECT quiz_id FROM java_target)
  AND q.id NOT IN (SELECT id FROM java_questions);

DELETE FROM questions q
WHERE q.quiz_id = (SELECT quiz_id FROM java_target)
  AND q.id NOT IN (SELECT id FROM java_questions);

INSERT INTO questions (id, quiz_id, type, text, image_url, code_snippet, explanation, score, sort_order)
SELECT s.id, t.quiz_id, 'mcq', s.text, '', s.code_snippet, s.explanation, 1, s.sort_order
FROM java_questions s
CROSS JOIN java_target t
ON CONFLICT (id) DO NOTHING;

-- Refresh wording for all seeded Java questions.
UPDATE questions q
SET text = s.text,
    code_snippet = s.code_snippet,
    explanation = s.explanation,
    sort_order = s.sort_order
FROM java_questions s
WHERE q.id = s.id
  AND q.quiz_id = (SELECT quiz_id FROM java_target)
  AND (q.text, q.code_snippet, q.explanation, q.sort_order)
      IS DISTINCT FROM
      (s.text, s.code_snippet, s.explanation, s.sort_order);

INSERT INTO options (question_id, text, is_correct, match_text, sort_order)
SELECT s.question_id, s.text, s.is_correct, '', s.sort_order
FROM java_options s
WHERE NOT EXISTS (
    SELECT 1 FROM options o WHERE o.question_id = s.question_id
);

-- Refresh option wording and correct-answer positions for every seeded Java question.
UPDATE options o
SET text = s.text,
    is_correct = s.is_correct
FROM java_options s
JOIN questions q ON q.id = s.question_id
WHERE o.question_id = s.question_id
  AND o.sort_order = s.sort_order
  AND q.quiz_id = (SELECT quiz_id FROM java_target)
  AND (o.text, o.is_correct) IS DISTINCT FROM (s.text, s.is_correct);

DO $$
BEGIN
    IF (SELECT count(*) FROM questions WHERE quiz_id = (SELECT quiz_id FROM java_target)) <> 24 THEN
        RAISE EXCEPTION 'Expected exactly twenty-four questions in the Java quiz';
    END IF;

    IF EXISTS (
        SELECT q.id
        FROM questions q
        JOIN java_questions s ON s.id = q.id
        LEFT JOIN options o ON o.question_id = q.id
        GROUP BY q.id
        HAVING count(o.id) <> 4
            OR count(o.id) FILTER (WHERE o.is_correct) <> 1
    ) THEN
        RAISE EXCEPTION 'Each seeded Java question must have four options and one correct answer';
    END IF;
END;
$$;

COMMIT;
