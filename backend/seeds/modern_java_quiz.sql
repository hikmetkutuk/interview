-- Modern Java quiz seed
-- 16 senaryo tabanlı soru: Java Mülakat Notları'ndaki Modern Java bölümünün 8 sorusu x 2 varyant.
-- Aynı konunun iki varyantı aynı sort_order değerini paylaşır (ör. mj-001 ve mj-001b).
-- Uygulama, her sort_order grubundan rastgele bir soru seçerek 8 soruluk bir sınav oluşturmalıdır.
-- Run explicitly against an existing database; this is not a schema migration.

BEGIN;

INSERT INTO categories (name, slug, description)
VALUES ('Modern Java', 'modern-java', 'Java 8 sonrası dil özellikleri: Stream API, Optional, lambda, record, sealed class, pattern matching, generics ve LTS sürümleri')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO quizzes (id, title, description, category_id, time_limit_seconds, passing_score)
SELECT 'c3f1a7e2-9b4d-4c8e-a6f0-2d5b8e1c7a94', 'Modern Java',
       'Senior mülakat: Modern Java üzerine 8 senaryo.',
       id, 1600, 70
FROM categories
WHERE slug = 'modern-java'
  AND NOT EXISTS (SELECT 1 FROM quizzes WHERE category_id = categories.id AND title = 'Modern Java');

CREATE TEMP TABLE mj_target ON COMMIT DROP AS
SELECT q.id::varchar(50) AS quiz_id
FROM quizzes q
JOIN categories c ON c.id = q.category_id
WHERE c.slug = 'modern-java' AND q.title = 'Modern Java';

DO $$
BEGIN
    IF (SELECT count(*) FROM mj_target) <> 1 THEN
        RAISE EXCEPTION 'Expected exactly one Modern Java quiz';
    END IF;
END;
$$;

UPDATE quizzes
SET description = 'Senior mülakat: Modern Java üzerine 8 senaryo.',
    time_limit_seconds = 1600,
    passing_score = 70
WHERE id::text = (SELECT quiz_id FROM mj_target);

CREATE TEMP TABLE mj_questions (
    id varchar(50) PRIMARY KEY,
    text text NOT NULL,
    code_snippet text NOT NULL,
    explanation text NOT NULL,
    sort_order integer NOT NULL
) ON COMMIT DROP;

INSERT INTO mj_questions VALUES

-- 1. Stream API ------------------------------------------------------------

('mj-001',
$q$Bir geliştirici, stream adımlarının hangi sırayla çalıştığını görmek için filter ve map içine log ekliyor. Aşağıdaki kod çalıştırıldığında konsola ne yazılır?$q$,
$code$List<String> names = List.of("ali", "veli", "ayse", "can");

Stream<String> stream = names.stream()
        .filter(n -> {
            System.out.print("F:" + n + " ");
            return n.length() > 3;
        })
        .map(n -> {
            System.out.print("M:" + n + " ");
            return n.toUpperCase();
        });

System.out.print("start ");
String first = stream.findFirst().orElseThrow();
System.out.print(first);$code$,
$e$Intermediate işlemler (filter, map) lazy'dir: stream tanımlandığında hiçbir şey çalışmaz, bu yüzden önce "start" yazılır. Terminal işlem (findFirst) zinciri başlatır ve elemanlar adım adım değil, eleman eleman işlenir: "ali" filtreden geçemez ve map'e hiç ulaşmaz; "veli" filtreden geçer, hemen map'e girer ve findFirst sonucu bulduğu için işlem durur (short-circuit). "ayse" ve "can" hiç işlenmez. Önce tüm elemanların filter'dan, sonra map'ten geçtiğini düşünmek klasik bir yanılgıdır; stream bir döngüler dizisi gibi değil, her eleman için tek bir hat (pipeline) gibi çalışır.$e$, 1),

('mj-001b',
$q$Bir CRM servisinde müşteriler e-posta adresine göre bir map'te toplanıyor. Kod testlerde sorunsuz çalışıyor, ama production'da bazı isteklerde IllegalStateException: Duplicate key hatası alınıyor. İnceleme sonucunda aynı e-posta adresiyle iki kez kaydolmuş müşteriler olduğu görülüyor. En doğru değerlendirme hangisidir?$q$,
$code$Map<String, Customer> byEmail = customers.stream()
        .collect(Collectors.toMap(Customer::email, c -> c));$code$,
$e$Collectors.toMap, aynı key ikinci kez geldiğinde hangi değerin kalacağını kendisi seçmez ve IllegalStateException fırlatır. Bu bir hata değil, bilinçli bir tasarımdır: çakışmada ne yapılacağı bir iş kararıdır. Üçüncü parametre olarak bir merge fonksiyonu verilir (ör. (a, b) -> a.updatedAt().isAfter(b.updatedAt()) ? a : b) ya da tüm kayıtlar gerekiyorsa groupingBy ile Map<String, List<Customer>> üretilir. forEach içinde map.put yapmak hatayı susturur ama bir müşteriyi sessizce kaybeder; üstelik lambda'yı dış state'i değiştiren bir side effect'e çevirir. Key burada String olduğu için Customer'ın equals/hashCode'u çakışmayı etkilemez. toMap'in kaynak listenin değiştirilebilir olup olmamasıyla da ilgisi yoktur.$e$, 1),

-- 2. Optional --------------------------------------------------------------

('mj-002',
$q$Çok kiracılı (multi-tenant) bir uygulamada kiracı konfigürasyonu önce yerel cache'ten okunuyor, bulunamazsa uzak bir konfigürasyon servisinden alınıyor. Cache isabet oranı %99 olmasına rağmen izleme ekranı, uzak servise her çağrıda istek gittiğini gösteriyor. Sorunun nedeni ve çözümü nedir?$q$,
$code$public Config getConfig(String tenantId) {
    return cache.find(tenantId)            // Optional<Config> döner
            .orElse(remoteConfigClient.fetch(tenantId));
}$code$,
$e$orElse sıradan bir metot argümanı alır ve Java'da argümanlar metot çağrılmadan önce değerlendirilir. Bu yüzden remoteConfigClient.fetch, Optional dolu olsa bile her seferinde çalışır; sonucu sadece kullanılmaz. orElseGet ise bir Supplier alır ve onu yalnızca Optional boşsa çağırır: orElseGet(() -> remoteConfigClient.fetch(tenantId)). Pahalı veya yan etkisi olan bir varsayılan değer her zaman orElseGet ile verilmelidir; orElse sabit ya da hazır bir değer için uygundur. Cache isabet oranı yüksek olduğuna göre sorun key eşleşmesinde değildir. orElseGet'in de argümanı önceden çalıştırdığı iddiası yanlıştır; if (isPresent()) bloğu da çalışır ama orElseGet aynı işi daha sade yapar.$e$, 2),

('mj-002b',
$q$Bir kod incelemesinde aşağıdaki üç Optional kullanımı tartışılıyor. findOrders için "sipariş yok" durumu boş listeyle temsil ediliyor; ayrıca bir "sonuç yok" durumu gerekmiyor. Entity için özel converter veya tip eşlemesi tanımlanmamış. Hangi değerlendirme doğrudur?$q$,
$code$// (1)
public Optional<Customer> findById(Long id) {
    Customer c = repository.lookup(id);
    if (c == null) {
        return null;
    }
    return Optional.of(c);
}

// (2)
public Optional<List<Order>> findOrders(Long customerId) { ... }

// (3)
@Entity
public class Customer {
    private Optional<String> nickname;
}$code$,
$e$Optional esas olarak dönüş tipinde "sonuç yok" durumunu ifade etmek için tasarlanmıştır. (1) Optional dönen bir metot null dönmemelidir; istemcinin Optional işlemleri NullPointerException ile sonuçlanabilir. Doğrusu return Optional.ofNullable(repository.lookup(id)). (2) Bu sözleşmede sipariş yokluğu boş listeyle zaten ifade edildiği için Optional<List<Order>> gereksiz ikinci bir boşluk kontrolü yaratır. Başka bir domain'de "sonuç yok" ile "sonuç var ama liste boş" ayrımı gerekiyorsa Optional<List> geçerli olabilir; dil tarafından yasak değildir. (3) Optional Serializable değildir ve standart bir JPA basic alan tipi değildir; özel eşleme tanımlanmayan bu entity'de nullable String daha uygundur. Optional'ın alan veya parametre tipi olarak kullanılması Java tarafından yasaklanmaz, ancak çoğu API'de gereksiz karmaşıklık yaratır. Gerekiyorsa entity getter'ı Optional döndürebilir.$e$, 2),

-- 3. Lambda ve functional interface ----------------------------------------

('mj-003',
$q$Bir geliştirici, siparişleri işlerken kaç tanesinin işlendiğini saymak istiyor ve aşağıdaki kodu yazıyor. Kod processed++ satırında derleme hatası veriyor. Hatanın nedeni ve en uygun çözüm hangisidir?$q$,
$code$int processed = 0;

orders.forEach(order -> {
    orderService.handle(order);
    processed++;   // derleme hatası
});

log.info("İşlenen sipariş: {}", processed);$code$,
$e$Lambda, dışarıdaki local değişkenin kendisini değil değerini yakalar (capture). Bu yüzden yakalanan değişken final veya effectively final olmalıdır; aksi halde lambda'daki kopya ile değişkenin güncel değeri birbirinden ayrılırdı. Burada esas iş orderService.handle gibi side effect içeren bir işlem; işlem ve sayaç birlikte gerekiyorsa en açık çözüm basit bir for döngüsüdür. Yalnızca giriş elemanlarının sayısı gerekiyorsa orders.size() yeterlidir. İşi stream'in bir ara adımına (ör. peek veya map) taşıyıp sonunda count() çağırmak iyi bir çözüm değildir: Java 9'dan beri count(), boyutu baştan bilinen (SIZED) pipeline'larda elemanları hiç dolaşmadan sonucu dönebilir ve ara adımdaki side effect hiç çalışmayabilir. AtomicInteger da derlenir, ama bunun nedeni thread-safe olması değil, referansın effectively final kalmasıdır; derleyici thread güvenliğine bakmaz. int[] dizisi hilesi de aynı nedenle derlenir, ancak paralel çalışmada güvenli değildir ve niyeti gizler. Local değişkenler volatile tanımlanamaz; volatile yalnızca alanlar için geçerlidir.$e$, 3),

('mj-003b',
$q$Bir rapor servisi, dosya yollarının içeriğini okuyup bir listeye topluyor. Files.readString bir IOException fırlatabildiği için aşağıdaki kod derlenmiyor. Hatanın nedeni ve uygun yaklaşım hangisidir?$q$,
$code$public List<String> readAll(List<Path> paths) {
    return paths.stream()
            .map(p -> Files.readString(p))   // derlenmiyor
            .toList();
}$code$,
$e$map metodu bir Function alır ve Function.apply hiçbir checked exception bildirmez. Bu yüzden lambda gövdesinden IOException dışarı çıkamaz. Çevreleyen metoda throws IOException eklemek yeterli değildir: lambda'nın hedef tipi olan Function'ın exception sözleşmesi değişmez. Uygun yaklaşım IOException'ı lambda içinde yakalayıp UncheckedIOException'a sarmaktır; bunu küçük bir yardımcı metoda almak okunabilirliği artırır. Checked exception'ı korumak isteniyorsa throws IOException bildiren bir metotta for döngüsü kullanılabilir. Checked exception bildiren özel bir functional interface, Stream.map'e doğrudan verilemez; Function'a dönüştüren ve exception'ı ele alan bir adaptör veya farklı bir API gerekir. Method reference'a geçmek yalnızca yazımı değiştirir, derleyici kontrolünü atlamaz. forEach'in aldığı Consumer da checked exception bildirmez.$e$, 3),

-- 4. Record ----------------------------------------------------------------

('mj-004',
$q$Bir ekip, Java 17'ye geçtikten sonra boilerplate kodu azaltmak için JPA ile yönetilen Order entity'sini bir record'a dönüştürmeyi öneriyor. Bu öneriyle ilgili en doğru değerlendirme hangisidir?$q$,
$code$@Entity
public record Order(
        @Id Long id,
        String customerEmail,
        OrderStatus status,
        BigDecimal total) {
}$code$,
$e$Record, sığ (shallowly) immutable bir veri taşıyıcısıdır: bileşen alanları private final, sınıf final'dır. Bu record'un otomatik constructor'ı tüm bileşenleri alır; otomatik bir parametresiz constructor üretilmez. Elle ek bir constructor yazılabilir, ancak bu record'u JPA entity'si yapmaz: Jakarta Persistence record tiplerini entity olarak kabul etmez; entity sınıfı final olmamalı ve public veya protected parametresiz constructor sağlamalıdır. Hibernate'in alt sınıf tabanlı lazy proxy yaklaşımı da final sınıfla uyumlu değildir. Bileşenlerden biri mutable bir List ise record deep immutable olmaz. Compact constructor'da List.copyOf yapısal değişiklikleri engeller, fakat listedeki mutable elemanları deep copy etmez. Record'un uygun kullanım alanları DTO, API request/response, projection ve value object'tir; Hibernate 6.2 ve sonrası record embeddable'ları da destekler. Otomatik equals'ın tüm bileşenleri karşılaştırması entity kimlik modeliyle ayrıca değerlendirilmelidir, ancak burada temel engel değildir. Record'lar interface uygulayabilir ve Serializable olabilir.$e$, 4),

('mj-004b',
$q$Bir ödeme servisinde tutarlar Money record'u ile modelleniyor ve bu record bir HashMap'te key olarak kullanılıyor. Aşağıdaki kod çalıştırıldığında ne yazılır ve neden?$q$,
$code$record Money(BigDecimal amount, String currency) {}

Map<Money, String> labels = new HashMap<>();
labels.put(new Money(new BigDecimal("10.0"), "TRY"), "on lira");

System.out.println(
        labels.get(new Money(new BigDecimal("10.00"), "TRY")));$code$,
$e$Record'un otomatik ürettiği equals ve hashCode, her bileşenin kendi equals ve hashCode metodunu kullanır. BigDecimal.equals ise yalnızca sayısal değeri değil ölçeği (scale) de karşılaştırır: 10.0 (scale 1) ile 10.00 (scale 2) equals'a göre eşit değildir, hashCode'ları da farklıdır. Bu yüzden get null döner. Sayısal karşılaştırma compareTo ile yapılır, ama record equals'ı compareTo'yu kullanmaz. Çözüm, değeri compact constructor'da normalize etmektir. Ölçek her para birimi için 2 değildir (JPY 0, KWD 3 ondalık kullanır); para biriminin veya domain'in kuralına göre belirlenmelidir, örneğin amount.setScale(Currency.getInstance(currency).getDefaultFractionDigits(), RoundingMode.HALF_EVEN). Böylece aynı tutar her zaman aynı temsile sahip olur ve record map key olarak güvenle kullanılabilir. Record'lar hashCode'u otomatik üretir ve bu hashCode tüm bileşenlerden hesaplanır.$e$, 4),

-- 5. Sealed class ve pattern matching --------------------------------------

('mj-005',
$q$Java 21 kullanan bir ödeme modülünde sonuçlar aşağıdaki sealed hiyerarşiyle modellenmiş. Ekip, onay bekleyen ödemeler için Pending adında yeni bir record ekliyor ve onu permits listesine yazıyor; message metodu ise değiştirilmiyor. Kodun son hali aşağıda. Proje yeniden derlendiğinde ne olur?$q$,
$code$sealed interface PaymentResult
        permits Approved, Declined, Failed, Pending {}

record Approved(String txId) implements PaymentResult {}
record Declined(String reason) implements PaymentResult {}
record Failed(Exception cause) implements PaymentResult {}
record Pending(String txId) implements PaymentResult {}   // yeni eklendi

// message metodu değiştirilmedi

String message(PaymentResult result) {
    return switch (result) {
        case Approved a -> "Ödeme tamam: " + a.txId();
        case Declined(var reason) -> "Reddedildi: " + reason;
        case Failed f -> "Hata, tekrar deneyin";
    };
}$code$,
$e$Sealed hiyerarşide izin verilen alt tipler derleyici tarafından bilinir. Switch'in exhaustive olması için tüm olası non-null değerleri kapsaması gerekir. Burada mevcut üç alt tip listelenmiştir; Pending eklenince switch eksik kalır ve yeniden derlemede hata verir. Aynı şekilde alt tipleri tek tek sayan başka switch'ler de güncellenmelidir. Default veya tüm hiyerarşiyi kapsayan bir üst tip pattern'i içeren switch'ler ise yeni alt tipi yakalayabilir; her default'suz switch'in mutlaka bozulacağı söylenemez. Yeni durumları derleme zamanında fark etmek isteniyorsa genel bir catch-all dalı eklememek faydalıdır. Switch eşleşme olmayınca null dönmez. Hiyerarşi değiştiği halde eski switch kodu yeniden derlenmezse yeni alt tip runtime'da MatchException'a neden olabilir. MatchException'ın başka bir nedeni de record pattern'inde accessor'ın exception fırlatmasıdır.$e$, 5),

('mj-005b',
$q$Bir sipariş sisteminde OrderCreated, OrderPaid ve OrderCancelled olmak üzere üç domain event'i var ve bu set nadiren değişiyor. Buna karşılık bu event'ler üzerinde çalışan işlemler (audit kaydı, raporlama projeksiyonu, e-posta bildirimi) farklı modüller tarafından sık sık ekleniyor. Bir geliştirici her işlem için event sınıflarına toAudit(), toProjection() gibi abstract metotlar eklemeyi, diğeri ise event'leri sealed interface yapıp her modülde pattern matching switch kullanmayı öneriyor. Hangi değerlendirme doğrudur?$q$,
'',
$e$Polymorphism, tip seti açık olduğunda ve davranış gerçekten tipin kendisine ait olduğunda iyi çalışır. Bu senaryoda durum tersidir: tip seti kapalı ve nadiren değişiyor, değişen şey tipler üzerinde çalışan işlemler. Her işlemi event sınıflarına abstract metot olarak eklemek, audit, raporlama ve e-posta gibi farklı modüllerin sorumluluklarını event'lerin içine taşır ve her yeni işlemde tüm event sınıflarını değiştirmeyi gerektirir. Sealed interface ile her modül kendi switch'ini yazar; yeni bir event eklendiğinde ise default içermeyen tüm switch'ler derleme hatası vererek güncellenmesi gereken yerleri gösterir. Default eklemek bu güvenceyi kaldırır. Visitor da çalışır, ama sealed + pattern matching aynı derleme zamanı güvencesini çok daha sade sağlar.$e$, 5),

-- 6. Switch expression, text block ve var ----------------------------------

('mj-006',
$q$Bir kod incelemesinde var kullanılan aşağıdaki dört satır değerlendiriliyor. Her satırı birbirinden bağımsız değerlendirin. Hangi değerlendirme doğrudur?$q$,
$code$public class ReportService {

    private var cache = new HashMap<String, Report>();       // (1)

    public void generate(Request request) {
        var users = new ArrayList<User>();                    // (2)
        var result = processor.process(request);              // (3)
        for (var entry : cache.entrySet()) { ... }            // (4)
    }
}$code$,
$e$var (Java 10) yalnızca local değişkenlerde kullanılabilir: metot içindeki değişkenler, for döngüsü değişkenleri ve try-with-resources. Alan, metot parametresi veya dönüş tipi olarak kullanılamaz; bu yüzden (1) derlenmez. var dinamik tipleme değildir: tip derleme zamanında sağ taraftan çıkarılır ve sonradan değişmez. (2) ve (4) derlenir ve tip açıkça anlaşıldığı için okunabilirliği artırır. (3) de derlenir; ama process'in ne döndürdüğü satırdan anlaşılmadığı için okuyucunun metoda gitmesini gerektirir ve okunabilirliği düşürür. Kural, var'ın tip zaten açıkça görünüyorsa kullanılmasıdır. Generic tiplerle kullanımı sorun değildir; sağ tarafta new ifadesi bulunması da zorunlu değildir.$e$, 6),

('mj-006b',
$q$Bir kargo modülünde teslimat ücreti, klasik bir switch statement ile hesaplanıyor. type değeri EXPRESS olduğunda fee kaç olur ve bu kod switch expression ile yazılsaydı ne değişirdi?$q$,
$code$enum DeliveryType { EXPRESS, STANDARD, PICKUP }

int fee = 0;
switch (type) {
    case EXPRESS:
        fee += 20;
    case STANDARD:
        fee += 10;
        break;
    case PICKUP:
        fee = 0;
}$code$,
$e$Klasik switch statement'ta case'ler arasında fall-through vardır: eşleşen case'ten sonra break görülene kadar alttaki case'lerin kodu da çalışır. EXPRESS eşleşir, fee 20 olur; break olmadığı için STANDARD'ın satırı da çalışır ve fee 30 olur; ardından break ile çıkılır. PICKUP'a ulaşılmaz. Java 14 ile gelen switch expression'da -> ile yazılan case'lerde fall-through yoktur; her case yalnızca kendi ifadesini çalıştırır ve switch bir değer döner: int fee = switch (type) { case EXPRESS -> 20; case STANDARD -> 10; case PICKUP -> 0; };. Birden fazla satır gerekirse blok içinden değer yield ile döndürülür. Ayrıca enum'un tüm değerleri karşılanmazsa switch expression derlenmez.$e$, 6),

-- 7. Generics, wildcard ve PECS --------------------------------------------

('mj-007',
$q$Bir yardımcı sınıfa, bir listedeki elemanları başka bir listeye kopyalayan generic bir metot yazılıyor. Metodun List<Integer> kaynağını List<Number> veya List<Object> hedefine kopyalayabilmesi, aynı zamanda tip güvenliğini koruması isteniyor. Bunu sağlayan imza hangisidir?$q$,
'',
$e$Generics invariant'tır: Integer, Number'ın alt tipi olsa da List<Integer>, List<Number>'ın alt tipi değildir. Esneklik wildcard'larla sağlanır ve kural PECS'tir: Producer Extends, Consumer Super. Kaynak liste sadece okunur, yani T üretir (producer): ? extends T. Hedef liste sadece yazılır, yani T tüketir (consumer): ? super T. JDK'daki Collections.copy(List<? super T> dest, List<? extends T> src) de bu imzayı kullanır. Wildcard'ların yerini değiştirmek, kaynaktan okumayı ve hedefe yazmayı engeller. List<?> hedefine null dışında eleman eklenemez. List<Object> hedefi ise yalnızca Object listelerini kabul eder; List<Number> verilemez.$e$, 7),

('mj-007b',
$q$Bir eğitim oturumunda array'lerin ve generic koleksiyonların alt tip ilişkisi tartışılıyor. Aşağıdaki iki kod parçasıyla ilgili hangi ifade doğrudur?$q$,
$code$// (1)
Object[] items = new String[2];
items[0] = "a";
items[1] = 42;

// (2)
List<Object> list = new ArrayList<String>();$code$,
$e$Array'ler covariant'tır: String[], Object[]'in alt tipidir, bu yüzden (1) derlenir. Ancak array kendi gerçek eleman tipini runtime'da bilir ve kontrol eder; String dizisine Integer yazılmaya çalışıldığında ArrayStoreException fırlatılır. Generics ise invariant'tır: ArrayList<String>, List<Object>'in alt tipi değildir ve (2) derlenmez. Olsaydı List<Object> referansıyla bir String listesine Integer eklenebilirdi. Generics bu hatayı runtime'dan derleme zamanına taşır. Type erasure, generic tip argümanının runtime'da nesne üzerinden bilinmemesi anlamına gelir; bu nedenle generic koleksiyonlarda bu kontrol derleyicinin işidir.$e$, 7),

-- 8. Java 17, 21 ve 25 LTS sürümleri ---------------------------------------

('mj-008',
$q$Java 17 ile çalışan bir Spring Boot servisi, her istekte birkaç dış HTTP servisini ve veritabanını bloklayan çağrılarla bekliyor. Yük arttığında thread havuzu doluyor ve istekler kuyrukta bekliyor. Ekip Java 21'e geçmeyi değerlendiriyor. Bu geçişle ilgili hangi ifade doğrudur?$q$,
'',
$e$Java 21 ile gelen virtual thread'ler, bloklayan bir I/O çağrısı sırasında taşıyıcı platform thread'i serbest bırakır. Böylece bekleyen çok sayıda istek az sayıda platform thread üzerinde taşınabilir; thread havuzunun dolması sorunu bu senaryoda büyük ölçüde hafifler. Java 21–23'te synchronized blok içinde bloklayan bir çağrı virtual thread'i taşıyıcıya sabitler (pinning); bu kısıt Java 24 ile büyük ölçüde kaldırıldı. Ancak virtual thread'ler CPU'yu çoğaltmaz, CPU-bound işleri hızlandırmaz. Dış kaynakların sınırları da ortadan kalkmaz: veritabanı connection pool'u hâlâ aynı anda kaç sorgunun çalışabileceğini belirler ve binlerce virtual thread bu havuzda bekleyebilir. Record, sealed class ve instanceof pattern matching Java 17'de zaten kalıcı özelliklerdir (record ve instanceof pattern matching 16'dan gelir). Java 21 bir LTS sürümüdür; ara sürümler 18, 19, 20, 22, 23 ve 24'tür.$e$, 8),

('mj-008b',
$q$Java 25'e geçen bir serviste her istek ayrı bir virtual thread'de işleniyor ve istek bağlamı (kiracı, kullanıcı, trace id) static bir ThreadLocal ile taşınıyor. Ekip bunu Java 25'te kalıcı hale gelen ScopedValue'ya taşımayı öneriyor. Bu geçişle ilgili en doğru değerlendirme hangisidir?$q$,
$code$// Mevcut
private static final ThreadLocal<RequestContext> CONTEXT = new ThreadLocal<>();

void handle(Request request) {
    CONTEXT.set(RequestContext.from(request));
    try {
        orderService.process(request);   // içeride CONTEXT.get()
    } finally {
        CONTEXT.remove();
    }
}

// Öneri
private static final ScopedValue<RequestContext> CONTEXT = ScopedValue.newInstance();

void handle(Request request) {
    ScopedValue.where(CONTEXT, RequestContext.from(request))
            .run(() -> orderService.process(request));   // içeride CONTEXT.get()
}$code$,
$e$ThreadLocal virtual thread'lerde de çalışır: her virtual thread kendi bağlamını tutar, bu yüzden geçiş zorunlu değildir. ThreadLocal'ın değeri çağrı zincirinden set ile değiştirilebilir ve remove unutulursa thread ömrü boyunca kalabilir. InheritableThreadLocal ile kalıtım etkinse child thread oluşturulurken thread-local eşlemeleri kopyalanır; bu, değerin deep copy edildiği anlamına gelmez. Çok sayıda thread'de bu eşlemelerin maliyeti büyür. ScopedValue'da referans where(...).run(...) ile sınırlı bir scope için bağlanır; set metodu yoktur ve scope bitince bağ otomatik kalkar veya dış scope'un bağı geri gelir. İç içe where ile yeniden bağlama yapılabilir. Bağlı nesne mutable ise kendi alanları değişebilir: ScopedValue nesneyi deep immutable yapmaz. Thread'ler arası paylaşımda immutable bağlam veya uygun senkronizasyon gerekir. Herhangi bir bağın olmadığı yerde get, NoSuchElementException fırlatır. StructuredTaskScope ile child thread'ler aynı bağları verimli biçimde devralabilir; sıradan bağımsız thread'ler bunları otomatik devralmaz. Java 25'te StructuredTaskScope hâlâ preview, ScopedValue ise kalıcıdır. Java 25 LTS'teki diğer kalıcı özellikler arasında flexible constructor bodies, module import declarations ve varsayılan olarak kapalı compact object headers bulunur.$e$, 8);

CREATE TEMP TABLE mj_options (
    question_id varchar(50) NOT NULL REFERENCES mj_questions(id),
    text text NOT NULL,
    is_correct boolean NOT NULL,
    sort_order integer NOT NULL,
    PRIMARY KEY (question_id, sort_order)
) ON COMMIT DROP;

INSERT INTO mj_options VALUES

('mj-001', $o$F:ali F:veli F:ayse F:can M:veli M:ayse start VELI$o$, false, 0),
('mj-001', $o$start F:ali F:veli F:ayse F:can M:veli M:ayse VELI$o$, false, 1),
('mj-001', $o$start F:ali F:veli M:veli VELI$o$, true, 2),
('mj-001', $o$start F:ali M:ali F:veli M:veli VELI$o$, false, 3),

('mj-001b', $o$Hangi kaydın kalacağı bir iş kararıdır; toMap'e merge fonksiyonu verilmeli ya da tüm kayıtlar için groupingBy kullanılmalıdır.$o$, true, 0),
('mj-001b', $o$toMap yerine forEach içinde map.put kullanılmalı; aynı key geldiğinde son kayıt öncekinin üzerine yazılır ve stream yan etkisiz kalır.$o$, false, 1),
('mj-001b', $o$Hata Customer'ın equals ve hashCode metotlarını override etmemesinden kaynaklanır; bu metotlar eklenince key çakışması ortadan kalkar.$o$, false, 2),
('mj-001b', $o$toMap değiştirilemeyen bir kaynakla çalışamaz; customers önce new ArrayList ile kopyalanırsa duplicate key hatası da ortadan kalkar.$o$, false, 3),

('mj-002', $o$Cache'in key karşılaştırması hatalıdır; tenantId'nin equals ile eşleşmemesi nedeniyle find çoğu çağrıda boş Optional döndürmektedir.$o$, false, 0),
('mj-002', $o$orElse ve orElseGet aynı şekilde çalışır; uzak çağrı isPresent kontrolü yapan ayrı bir if bloğuna taşınırsa gereksiz istekler durur.$o$, false, 1),
('mj-002', $o$Uzak istemci kendi içinde periyodik yenileme yapıyordur; orElse argümanını yalnızca Optional boşken değerlendirdiği için kod doğrudur.$o$, false, 2),
('mj-002', $o$orElse'e verilen ifade, Optional dolu olsa bile çağrıdan önce çalışır; varsayılan değer orElseGet ile tembel üretilmelidir.$o$, true, 3),

('mj-002b', $o$Yalnızca (1) sorunludur; (2) boş liste ile hiç sorgulanmamış durumu ayırt ettiği için, (3) ise null kontrolünü azalttığı için önerilir.$o$, false, 0),
('mj-002b', $o$Üçü de sorunludur: (1) null yerine Optional.ofNullable dönmeli, (2) boş liste dönmeli, (3) Optional entity alanında kullanılmamalıdır.$o$, true, 1),
('mj-002b', $o$(1) doğrudur, çünkü null dönüşü istemcinin get çağrısında hata almasını önler; (2) ve (3) ise Optional'ın amacına uygun kullanımlardır.$o$, false, 2),
('mj-002b', $o$(1) ve (2) doğrudur; yalnızca (3) sorunludur, çünkü Optional alanlar her erişimde yeni bir nesne oluşturduğu için bellek tüketimini artırır.$o$, false, 3),

('mj-003', $o$Değişken volatile tanımlanmalıdır; lambda başka bir thread'de çalışabileceği için derleyici görünürlük garantisi ister.$o$, false, 0),
('mj-003', $o$Lambda değişkenin değerini yakalar, bu yüzden effectively final olmalı; işlem ve sayaç birlikte gerekiyorsa for döngüsü kullanılmalı.$o$, true, 1),
('mj-003', $o$Sayaç int[] processed = {0} olarak tanımlanmalı; dizi referansı final kaldığı için kod derlenir ve paralel stream'de de güvenle çalışır.$o$, false, 2),
('mj-003', $o$AtomicInteger kullanılmalıdır; derleyici lambda içinde yalnızca thread-safe tiplerin değiştirilmesine izin verdiği için int reddedilir.$o$, false, 3),

('mj-003b', $o$Metodun imzasına throws IOException eklenmelidir; lambda içinde oluşan exception, onu çağıran readAll metoduna doğal olarak iletilir.$o$, false, 0),
('mj-003b', $o$map yerine forEach ile listeye ekleme yapılmalıdır; forEach'in aldığı Consumer, Function'dan farklı olarak checked exception fırlatabilir.$o$, false, 1),
('mj-003b', $o$Function.apply checked exception bildirmez; IOException lambda içinde yakalanıp UncheckedIOException gibi bir tipe sarılmalıdır.$o$, true, 2),
('mj-003b', $o$Lambda yerine Files::readString method reference'ı kullanılmalıdır; method reference'larda derleyici checked exception kontrolü yapmaz.$o$, false, 3),

('mj-004', $o$Uygun değil: JPA parametresiz constructor ve değişebilen state ister, lazy proxy için final olmayan sınıf gerekir; record DTO'da kullanılır.$o$, true, 0),
('mj-004', $o$Uygundur; record'lar Java 16'dan beri JPA tarafından entity olarak desteklenir, yalnızca @Id alanının compact constructor'da atanması gerekir.$o$, false, 1),
('mj-004', $o$Uygundur ama equals ve hashCode override edilmelidir; record'un ürettiği equals tüm alanları karşılaştırır, bunun dışında bir engel yoktur.$o$, false, 2),
('mj-004', $o$Uygun değildir, çünkü record'lar interface uygulayamaz ve Serializable olamaz; bu nedenle JPA provider'ı onları veritabanına yazamaz.$o$, false, 3),

('mj-004b', $o$on lira; record'un ürettiği equals sayısal bileşenleri compareTo ile karşılaştırır, bu yüzden 10.0 ile 10.00 eşit kabul edilir.$o$, false, 0),
('mj-004b', $o$null; record'lar hashCode üretmez, bu yüzden HashMap'te key olarak kullanılabilmesi için hashCode metodunun elle yazılması gerekir.$o$, false, 1),
('mj-004b', $o$on lira; iki nesnenin toString çıktısı farklı olsa da record'un hashCode değeri yalnızca String tipindeki currency alanından üretilir.$o$, false, 2),
('mj-004b', $o$null; record equals'ı BigDecimal.equals'ı kullanır, o da ölçeği karşılaştırır. amount compact constructor'da normalize edilmeli.$o$, true, 3),

('mj-005', $o$Kod derlenir; Pending geldiğinde hiçbir case eşleşmediği için switch ifadesi null döner ve message metodu null değer döndürür.$o$, false, 0),
('mj-005', $o$Kod derlenir; Pending geldiğinde runtime'da MatchException fırlatılır. Bu yüzden her switch'e bir default dalı eklenmesi gerekir.$o$, false, 1),
('mj-005', $o$message metodundaki switch derleme hatası verir; Pending'i kapsayan yeni bir case eklenerek bu switch tamamlanmalıdır.$o$, true, 2),
('mj-005', $o$Kod derlenir; sealed hiyerarşilerde derleyici yeni tipin en yakın atasının case'ini seçer ve Pending, Failed dalına düşer.$o$, false, 3),

('mj-005b', $o$Abstract metot yaklaşımı doğrudur; tip üzerinde switch yapmak her durumda bir anti-pattern'dir ve polymorphism her zaman tercih edilmelidir.$o$, false, 0),
('mj-005b', $o$Sealed yaklaşımı daha uygundur: tip seti kapalı, işlemler sık değişiyor. Yeni bir event eklenirse derleyici eksik switch'leri gösterir.$o$, true, 1),
('mj-005b', $o$Sealed yaklaşımı uygundur, ancak yeni event'ler mevcut modülleri bozmasın diye her switch'e default dalı eklenmesi gerekir.$o$, false, 2),
('mj-005b', $o$İkisi de uygun değildir; Java'da kapalı bir hiyerarşi için derleme zamanı güvencesi veren tek yöntem Visitor tasarım kalıbıdır.$o$, false, 3),

('mj-006', $o$(2) derlenmez, çünkü var generic tip argümanı içeren ifadelerle kullanılamaz; diğer satırlar derlenir ve kullanımları uygundur.$o$, false, 0),
('mj-006', $o$Hepsi derlenir; var, tipin runtime'da belirlenmesini sağlar, bu yüzden alanlarda da metot içindeki değişkenlerde de kullanılabilir.$o$, false, 1),
('mj-006', $o$(3) derlenmez, çünkü var yalnızca sağ tarafta new ifadesi bulunduğunda kullanılabilir; diğer üç satır derlenir ve uygundur.$o$, false, 2),
('mj-006', $o$(1) derlenmez, var yalnızca local değişkenlerde kullanılır. (3) derlenir ama dönüş tipi görünmediği için okunabilirliği düşürür.$o$, true, 3),

('mj-006b', $o$30; break olmadığı için STANDARD'a düşer. -> ile yazılan switch expression'da fall-through yoktur, her case kendi değerini döner.$o$, true, 0),
('mj-006b', $o$20; Java her case'ten sonra switch'ten otomatik olarak çıkar, break ifadesi yalnızca okunabilirliği artırmak için kullanılır.$o$, false, 1),
('mj-006b', $o$30; switch expression'da da aynı fall-through davranışı sürer, aradaki tek fark switch expression'ın bir değer döndürebilmesidir.$o$, false, 2),
('mj-006b', $o$0; fall-through PICKUP'a kadar sürer ve fee = 0 ataması, önceki case'lerde eklenen 20 ve 10 değerlerinin üzerine yazar.$o$, false, 3),

('mj-007', $o$<T> void copy(List<? super T> src, List<? extends T> dest)$o$, false, 0),
('mj-007', $o$<T> void copy(List<? extends T> src, List<? super T> dest)$o$, true, 1),
('mj-007', $o$void copy(List<?> src, List<?> dest)$o$, false, 2),
('mj-007', $o$<T> void copy(List<T> src, List<Object> dest)$o$, false, 3),

('mj-007b', $o$İkisi de derlenir; (1) runtime'da ArrayStoreException, (2) ise listeye ilk Integer eklendiğinde ClassCastException fırlatır.$o$, false, 0),
('mj-007b', $o$(1) derleme hatası verir, (2) derlenir; çünkü generic koleksiyonlar covariant, array'ler ise invariant olarak tasarlanmıştır.$o$, false, 1),
('mj-007b', $o$İkisi de derlenir ve sorunsuz çalışır; type erasure nedeniyle hem array hem liste runtime'da yalnızca Object referansları tutar.$o$, false, 2),
('mj-007b', $o$(2) derlenmez; (2) kaldırılırsa (1) derlenir ama String dizisine Integer yazılırken runtime'da ArrayStoreException fırlatılır.$o$, true, 3),

('mj-008', $o$Virtual thread'ler, bloklayan I/O'da bekleyen çok sayıda isteği az sayıda platform thread üzerinde taşır; CPU-bound işleri hızlandırmaz.$o$, true, 0),
('mj-008', $o$Virtual thread'lerle her istek kendi thread'ini alacağı için veritabanı connection pool'unun boyutu artık bir darboğaz oluşturmaz.$o$, false, 1),
('mj-008', $o$Record, sealed class ve instanceof pattern matching Java 21 ile kalıcı hale gelir; Java 17'de bu özellikler yalnızca preview olarak bulunur.$o$, false, 2),
('mj-008', $o$Java 21 bir ara sürümdür; Java 17'den sonraki ilk LTS sürüm 25 olduğu için production geçişi Java 25'e kadar ertelenmelidir.$o$, false, 3),

('mj-008b', $o$ThreadLocal virtual thread'lerde çalışmaz; bir virtual thread farklı taşıyıcı thread'lere geçebildiği için değer kaybolur, bu nedenle geçiş zorunludur.$o$, false, 0),
('mj-008b', $o$ScopedValue da ThreadLocal gibi set metoduyla güncellenebilir; aradaki tek fark, remove çağrısının blok sonunda JVM tarafından yapılmasıdır.$o$, false, 1),
('mj-008b', $o$Bağ scope ile sınırlıdır ve otomatik kalkar; set yoktur ama iç içe yeniden bağlama mümkündür. Bağlı nesne kendiliğinden immutable olmaz.$o$, true, 2),
('mj-008b', $o$Geçişin bir faydası yoktur; ScopedValue Java 25'te hâlâ preview olduğu için production'da --enable-preview bayrağı ile çalıştırılması gerekir.$o$, false, 3);

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM questions q
        JOIN mj_questions s ON s.id = q.id
        WHERE q.quiz_id IS DISTINCT FROM (SELECT quiz_id FROM mj_target)
    ) THEN
        RAISE EXCEPTION 'A Modern Java question ID is already used by another quiz';
    END IF;
END;
$$;

-- Any other question in this quiz was not created by this seed (e.g. added manually); stop instead of deleting it.
DO $$
DECLARE
    unknown_ids text;
BEGIN
    SELECT string_agg(q.id, ', ' ORDER BY q.id) INTO unknown_ids
    FROM questions q
    WHERE q.quiz_id = (SELECT quiz_id FROM mj_target)
      AND q.id NOT IN (SELECT id FROM mj_questions);
    IF unknown_ids IS NOT NULL THEN
        RAISE EXCEPTION 'Modern Java quiz contains questions not managed by this seed: %', unknown_ids;
    END IF;
END;
$$;

INSERT INTO questions (id, quiz_id, type, text, image_url, code_snippet, explanation, score, sort_order)
SELECT s.id, t.quiz_id, 'mcq', s.text, '', s.code_snippet, s.explanation, 1, s.sort_order
FROM mj_questions s
CROSS JOIN mj_target t
ON CONFLICT (id) DO NOTHING;

-- Refresh wording for all seeded Modern Java questions.
UPDATE questions q
SET text = s.text,
    code_snippet = s.code_snippet,
    explanation = s.explanation,
    sort_order = s.sort_order
FROM mj_questions s
WHERE q.id = s.id
  AND q.quiz_id = (SELECT quiz_id FROM mj_target)
  AND (q.text, q.code_snippet, q.explanation, q.sort_order)
      IS DISTINCT FROM
      (s.text, s.code_snippet, s.explanation, s.sort_order);

INSERT INTO options (question_id, text, is_correct, match_text, sort_order)
SELECT s.question_id, s.text, s.is_correct, '', s.sort_order
FROM mj_options s
WHERE NOT EXISTS (
    SELECT 1 FROM options o WHERE o.question_id = s.question_id
);

-- Refresh option wording and correct-answer positions for every seeded Modern Java question.
UPDATE options o
SET text = s.text,
    is_correct = s.is_correct
FROM mj_options s
JOIN questions q ON q.id = s.question_id
WHERE o.question_id = s.question_id
  AND o.sort_order = s.sort_order
  AND q.quiz_id = (SELECT quiz_id FROM mj_target)
  AND (o.text, o.is_correct) IS DISTINCT FROM (s.text, s.is_correct);

DO $$
BEGIN
    IF (SELECT count(*) FROM questions WHERE quiz_id = (SELECT quiz_id FROM mj_target)) <> 16 THEN
        RAISE EXCEPTION 'Expected exactly sixteen questions in the Modern Java quiz';
    END IF;

    IF EXISTS (
        SELECT q.id
        FROM questions q
        JOIN mj_questions s ON s.id = q.id
        LEFT JOIN options o ON o.question_id = q.id
        GROUP BY q.id
        HAVING count(o.id) <> 4
            OR count(o.id) FILTER (WHERE o.is_correct) <> 1
    ) THEN
        RAISE EXCEPTION 'Each seeded Modern Java question must have four options and one correct answer';
    END IF;
END;
$$;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM questions
        WHERE quiz_id = (SELECT quiz_id FROM mj_target)
        GROUP BY sort_order
        HAVING count(*) <> 2
    ) THEN
        RAISE EXCEPTION 'Each Modern Java topic (sort_order) must have exactly two variants';
    END IF;

    IF (SELECT array_agg(DISTINCT sort_order ORDER BY sort_order)
        FROM questions
        WHERE quiz_id = (SELECT quiz_id FROM mj_target)) IS DISTINCT FROM ARRAY[1,2,3,4,5,6,7,8] THEN
        RAISE EXCEPTION 'Expected Modern Java topic groups 1 to 8';
    END IF;
END;
$$;

COMMIT;
