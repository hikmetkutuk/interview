-- Senior Java quiz seed
-- 14 core questions + 2 hard/bonus questions
-- Run explicitly against an existing database; this is not a schema migration.

BEGIN;

INSERT INTO categories (name, slug, description)
VALUES ('Java', 'java', 'Core Java, koleksiyonlar, bellek yönetimi, exception yönetimi ve dil davranışları')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO quizzes (id, title, description, category_id, time_limit_seconds, passing_score)
SELECT 'e7a6f6ad-4f5d-4e30-a2ab-9c9b431b4d51', 'Java',
       'Senior mülakat: Core Java üzerine 14 temel + 2 zor/bonus senaryo.',
       id, 3000, 70
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
SET description = 'Senior mülakat: Core Java üzerine 14 temel + 2 zor/bonus senaryo.',
    time_limit_seconds = 3000
WHERE id::text = (SELECT quiz_id FROM java_target);

CREATE TEMP TABLE java_questions (
    id varchar(50) PRIMARY KEY,
    text text NOT NULL,
    code_snippet text NOT NULL,
    explanation text NOT NULL,
    sort_order integer NOT NULL UNIQUE
) ON COMMIT DROP;

INSERT INTO java_questions VALUES

('java-001',
$q$Java 17 ile çalışan bir raporlama servisi binlerce satırlık CSV çıktısını döngü içinde üretiyor ve her iterasyonda result = result + line kullanıyor. Kod tek thread'de çalışıyor. En uygun yaklaşım ve gerekçesi hangisidir?$q$,
'',
$e$String immutable olduğu için döngüdeki her birleştirme yeni bir String üretir ve o ana kadar biriken içeriği yeniden kopyalar; toplam maliyet satır sayısıyla karesel büyür. Java 9+ ile + işlemi invokedynamic (StringConcatFactory) üzerinden optimize edilir, ancak bu optimizasyon tek bir ifade içindir; döngünün iterasyonları arasında ortak bir buffer kullanılmaz. Doğru çözüm döngü öncesinde bir StringBuilder oluşturup append etmektir. StringBuffer da mutable'dır fakat synchronized olduğundan tek thread'de gereksiz maliyet taşır. concat da her çağrıda yeni bir String üretir.$e$, 1),

('java-002',
$q$Tek thread'li bir uygulamada HashMap<OrderKey, Order> kullanılıyor. Map'e eklenen aynı key referansıyla yapılan map.get(key) bazen null dönüyor; buna rağmen map.size() değişmemiş ve keySet() üzerinde gezildiğinde key görünüyor. OrderKey'in equals/hashCode metotları customerId ve orderNo alanlarını kullanıyor ve customerId için public bir setter var. En olası neden nedir?$q$,
'',
$e$HashMap entry'yi ekleme anındaki hash değerine göre bir bucket'a yerleştirir ve bu hash'i entry içinde saklar. Key eklendikten sonra hashCode hesabına katılan customerId değiştirilirse get çağrısı yeni hash ile farklı bir bucket'a bakar ya da saklanan hash ile eşleşme bulamaz; entry ise eski yerinde durmaya devam eder. Bu yüzden size ve keySet entry'yi gösterirken get bulamaz. Aynı referansla yapılan aramada equals sözleşmesinin farklı nesneler arasında bozuk olması bu belirtiyi açıklamaz. Tree bin'ler Comparable olmayan key'leri de arayabilir. Çözüm hashCode/equals'a katılan alanları immutable yapmaktır.$e$, 2),

('java-003',
$q$Aşağıdaki cache kodunda yük testi sırasında aynı key için buildReport metodunun birden fazla kez çalıştığı görülüyor. buildReport yaklaşık 2 saniye süren pahalı bir hesaplama yapıyor. En doğru düzeltme ve dikkat edilmesi gereken nokta hangisidir?$q$,
$code$private final Map<String, Report> cache = new ConcurrentHashMap<>();

Report get(String key) {
    if (!cache.containsKey(key)) {
        cache.put(key, buildReport(key));
    }
    return cache.get(key);
}$code$,
$e$ConcurrentHashMap'in her metodu tek başına thread-safe'tir, ancak containsKey ve put art arda çağrıldığında aralarında başka bir thread aynı key'i ekleyebilir; bu check-then-act yarışıdır. computeIfAbsent hesaplamayı aynı key için bir kez yapar. Bununla birlikte mapping fonksiyonu çalışırken ilgili bin kilitli kalır; aynı bin'e düşen diğer key'ler bekleyebilir ve fonksiyonun içinden map değiştirilmemelidir (Java 9+ bu durumda IllegalStateException fırlatabilir). Çok uzun hesaplamalarda CompletableFuture değerleri saklayan bir cache veya Caffeine gibi bir kütüphane değerlendirilebilir. putIfAbsent(key, buildReport(key)) çağrısında buildReport, putIfAbsent çağrılmadan önce her seferinde çalışır. Metodu synchronized yapmak tüm key'ler için tek kilit oluşturur.$e$, 3),

('java-004',
$q$Aşağıdaki kodun çıktısı nedir?$q$,
$code$String a = new String("java");
String b = new String("java");
String c = "java";
String d = "java";

System.out.println(a == b);
System.out.println(a.equals(b));
System.out.println(c == d);
System.out.println(a.intern() == c);$code$,
$e$Object referanslarında == aynı nesneyi gösterip göstermediğini, equals ise sınıfın tanımladığı mantıksal eşitliği kontrol eder. a ve b new ile oluşturulan iki ayrı nesnedir; a == b false, a.equals(b) true olur. Aynı içerikli string literal'ları JLS gereği intern edilir, bu yüzden c == d garanti olarak true'dur. a.intern() pool'daki kanonik "java" nesnesini döndürür, bu da c ile aynı nesnedir; sonuç true olur. İçerik karşılaştırmasında == yerine equals veya null-safe Objects.equals kullanılmalıdır.$e$, 4),

('java-005',
$q$Aşağıdaki User sınıfının immutable olması isteniyor. Bu kod hakkında en doğru değerlendirme hangisidir?$q$,
$code$public final class User {
    private final List<String> roles;

    public User(List<String> roles) {
        this.roles = roles;
    }

    public List<String> getRoles() {
        return Collections.unmodifiableList(roles);
    }
}$code$,
$e$Getter'daki Collections.unmodifiableList dış kodun dönen liste üzerinden değişiklik yapmasını engeller, ancak kopya değil bir görünümdür (view). Constructor dışarıdan gelen listeyi doğrudan sakladığı için çağıran taraf elindeki referansla listeyi değiştirebilir ve User'ın state'i değişir. Doğru çözüm constructor'da List.copyOf(roles) ile kopya almaktır; List.copyOf zaten değiştirilemez bir liste döndürdüğü için getter onu doğrudan dönebilir. List.copyOf null eleman kabul etmez (NullPointerException). Alanın final olması yalnızca referansın yeniden atanmasını engeller. Elemanlar mutable nesneler olsaydı onların aliasing riski ayrıca ele alınmalıydı.$e$, 5),

('java-006',
$q$Aşağıdaki ifadelerden hangisi Java'da stack ve heap için en doğru açıklamadır?$q$,
'',
$e$Her thread kendi stack'ine sahiptir; method çağrı frame'leri ve local değişkenler bu frame'lerde tutulur. Nesneler kavramsal olarak heap'te yaşar ve thread'ler arasında paylaşılabilir; paylaşım static alanlarla sınırlı değildir, bir nesne referansı herhangi bir yolla başka bir thread'e geçebilir. Bir nesnenin primitive field'ı nesneyle birlikte heap'tedir. JIT, escape analysis ile metottan kaçmayan bir nesneyi hiç heap'e ayırmadan scalar replacement uygulayabilir; bu bir dil garantisi değil, bir optimizasyondur. Derin recursion StackOverflowError'a, yetersiz heap OutOfMemoryError'a yol açar.$e$, 6),

('java-007',
$q$Bir dosya içe aktarma servisinde üç durum oluşabiliyor: (1) kullanıcının yüklediği dosyada zorunlu bir kolon eksik, (2) dosya diskten okunurken IOException, (3) çok büyük dosyalarda OutOfMemoryError. Exception tasarımı açısından en doğru yaklaşım hangisidir?$q$,
'',
$e$Eksik kolon bir iş kuralı ihlalidir ve anlamlı bir domain exception'ı ile bildirilmelidir. IOException teknik bir hatadır; bağlam eklenerek sarılabilir ancak cause korunmalıdır, aksi halde kök neden kaybolur. Error türleri (OutOfMemoryError gibi) JVM seviyesindeki ciddi durumları temsil eder ve normal recovery akışının parçası değildir; catch (Exception e) zaten Error yakalamaz, catch (Throwable) ile yakalayıp devam etmek ise JVM'yi tutarsız bir durumda çalıştırmaya devam etmek demektir. Büyük dosya sorununun çözümü tasarımdadır: dosyayı tamamen belleğe almak yerine akış (streaming) ile işlemek. System.gc() çağrısı yalnızca bir istektir ve sorunu çözmez.$e$, 7),

('java-008',
$q$Bir Spring Boot uygulamasında repository, service ve controller katmanlarının her biri aynı exception'ı yakalayıp logluyor, sonra yeni bir RuntimeException ile tekrar fırlatıyor. Production loglarında aynı hata üç kez görünüyor ve root cause kayboluyor. En doğru yaklaşım hangisidir?$q$,
'',
$e$Exception yalnızca gerçekten handle edilebildiği veya anlamlı şekilde çevrilebildiği katmanda yakalanmalıdır. Her katmanda loglamak, cause korunsa bile aynı hatayı tekrar tekrar yazdırır ve log gürültüsü üretir. Teknik bir exception domain exception'a çevrilecekse yalnızca mesaj kopyalanmamalı, cause olarak eklenmelidir. Loglama ve hata response'u üretimi tek bir merkezde, örneğin @RestControllerAdvice içinde toplanmalıdır; her controller'da ayrı try/catch yazmak tutarsız response'lara yol açar. Hassas bilgiler response'a ve loglara yazılmamalıdır, ancak bu stack trace'i tamamen atmak anlamına gelmez.$e$, 8),

('java-009',
$q$Bir framework runtime sırasında class üzerindeki annotation'ları, field'ları ve method'ları inceleyerek bean oluşturuyor. Bu mekanizma ve trade-off'ları açısından en doğru değerlendirme hangisidir?$q$,
'',
$e$Reflection runtime'da Class, Method, Field ve Constructor gibi metadata üzerinden sınıf yapısını incelemeye ve dinamik erişime imkân verir; Spring, Hibernate ve Jackson bu mekanizmayı yoğun kullanır. Bir annotation'ın runtime'da okunabilmesi için @Retention(RetentionPolicy.RUNTIME) olması gerekir; CLASS retention'lı annotation'lar class dosyasında bulunur ama reflection ile görünmez. Java 9+ modül sisteminde, açılmamış (opens edilmemiş) paketlerin private üyelerine setAccessible(true) ile erişim engellenir. Reflection çağrıları JIT tarafından belirli ölçüde optimize edilebilir, ancak type safety kaybı ve bakım maliyeti devam eder. Compile-time annotation processing ise farklı bir mekanizmadır.$e$, 9),

('java-010',
$q$Bir Spring uygulamasında kullanıcı isteklerinden toplanan veriler bir service sınıfındaki public static ArrayList içinde tutuluyor. Uygulama birden fazla request thread'i ile çalışıyor; zaman zaman kayıtlar kayboluyor ve testler birbirini etkiliyor. Sorunun temel nedeni nedir?$q$,
'',
$e$Static alanlar instance'a değil class'a aittir; bu liste tüm request thread'leri ve aynı JVM'de çalışan testler arasında paylaşılır. ArrayList senkronize olmadığı için eşzamanlı eklemelerde veri kaybı veya tutarsız durum oluşabilir. synchronizedList thread-safety sorununu çözer, ancak paylaşılan state testler arasında sızmaya devam eder. Spring bean'leri varsayılan olarak singleton scope'tadır, request scope değildir. final referans listenin içeriğini korumaz. Çözüm mutable static state'ten kaçınmak, state'i uygun scope'ta bir bean'e veya kalıcı bir depoya taşımaktır.$e$, 10),

('java-011',
$q$Bir uygulamada liste üzerinde çok sık random access ve iteration yapılıyor, ortadan ekleme/silme ise nadir. ArrayList ve LinkedList arasında hangi tercih daha uygundur?$q$,
'',
$e$ArrayList dinamik dizi tabanlıdır; index ile erişim O(1), sona ekleme amortized O(1)'dir. Ardışık bellek düzeni sayesinde iteration CPU cache'inden iyi yararlanır; ArrayList'in iterator'ı da her adımda O(1) maliyetlidir. LinkedList'te index ile erişim O(n)'dir ve her node ek referanslar ile ayrı bir nesne olarak bellekte dağınık durur. LinkedList'te add(index, e) önce node'u bulmak için O(n) yürür; O(1) olan yalnızca node elde edildikten sonraki bağlantı değişikliğidir. Queue/deque ihtiyacında ArrayDeque ayrıca değerlendirilmelidir.$e$, 11),

('java-012',
$q$Bir Person nesnesi kopyalanıyor ancak içindeki mutable Address nesnesi iki kopya tarafından da paylaşılmaya devam ediyor. personB.getAddress().setCity("Ankara") çağrıldığında personA da etkileniyor. Bu durum nasıl açıklanır ve nasıl düzeltilir?$q$,
'',
$e$Bu shallow copy davranışıdır: üst nesne kopyalanır ancak nested mutable nesnelerin referansları paylaşılır. Object.clone() varsayılan olarak shallow copy yapar. address alanını final yapmak yalnızca referansın yeniden atanmasını engeller, Address nesnesinin değişmesini engellemez. Çözüm ya kopyalama sırasında Address'i de kopyalamak (deep copy) ya da Address'i immutable yapıp değişikliği yeni bir Address nesnesiyle ifade etmektir. Immutable nesneler güvenle paylaşılabildiği için gereksiz deep copy'nin bellek ve performans maliyetinden de kaçınılmış olur.$e$, 12),

('java-013',
$q$Aşağıdaki kod çalıştıktan sonra dışarıdaki reference değişkeninin User("B") nesnesini göstermesi bekleniyor ama göstermiyor. Java'nın parametre aktarım modeli açısından en doğru açıklama hangisidir?$q$,
$code$void replace(User user) {
    user = new User("B");
}

User reference = new User("A");
replace(reference);$code$,
$e$Java her zaman pass-by-value kullanır. Object gönderildiğinde nesnenin kendisi değil, referans değerinin bir kopyası metoda verilir. replace içindeki user değişkenine yeni bir nesne atamak yalnızca bu local kopyayı değiştirir. Buna karşılık user.setName(...) gibi aynı nesnenin state'ini değiştiren bir çağrı dışarıdan gözlenebilir, çünkü iki referans aynı nesneyi gösterir. İstenen davranış için metot yeni nesneyi döndürmeli ve çağıran taraf atamayı kendisi yapmalıdır.$e$, 13),

('java-014',
$q$Java generics'te type erasure için aşağıdakilerden hangisi doğrudur?$q$,
'',
$e$Type erasure nedeniyle bir nesnenin tip argümanı runtime'da bilinmez: new ArrayList<String>() ve new ArrayList<Integer>() aynı Class nesnesine (ArrayList.class) sahiptir. Ancak field, method ve superclass bildirimlerindeki generic tipler class dosyasında Signature attribute olarak saklanır ve reflection ile okunabilir; Jackson'ın TypeReference ve Gson'ın TypeToken yaklaşımları anonim subclass'ın superclass bilgisini okuyarak bu sayede çalışır. new T() ve T.class yazılamaz; bunun yerine Class<T> veya Supplier<T> parametre olarak alınır.$e$, 14),

('java-015',
$q$[ZOR / BONUS] Aşağıdaki kod çalıştırıldığında ne olur?$q$,
$code$List<String> items = new ArrayList<>(List.of("a", "b", "c"));

for (String item : items) {
    if (item.equals("b")) {
        items.remove(item);
    }
}

System.out.println(items);$code$,
$e$Enhanced for döngüsü ArrayList'in iterator'ını kullanır. hasNext() yalnızca cursor != size kontrolü yapar; fail-fast modCount kontrolü ise next() içinde yapılır. "b" silindikten sonra size 2 olur ve cursor zaten 2'dedir; hasNext() false döner, next() hiç çağrılmaz ve exception fırlatılmaz. Sonuç [a, c] olur ve "c" hiç ziyaret edilmez. "a" silinseydi döngü devam eder ve bir sonraki next() çağrısında ConcurrentModificationException fırlatılırdı. Bu örnek, fail-fast davranışın bir garanti değil best-effort bir hata tespiti olduğunu gösterir. Doğru çözüm iterator.remove() veya items.removeIf(...) kullanmaktır.$e$, 15),

('java-016',
$q$[ZOR / BONUS] Aşağıdaki metotta cache hit oranı yüksek olmasına rağmen veritabanı yükü azalmıyor. Neden?$q$,
$code$User find(String id) {
    return Optional.ofNullable(cache.get(id))
                   .orElse(repository.load(id));
}$code$,
$e$orElse sıradan bir metot argümanı aldığı için repository.load(id), Optional dolu olsa bile orElse çağrılmadan önce her seferinde çalıştırılır; cache hit olsa da veritabanına gidilir. orElseGet(() -> repository.load(id)) ise Supplier'ı yalnızca Optional boşsa çalıştırır. Genel olarak Optional, bir metodun değer döndürmeyebileceğini return type'ta ifade etmek için uygundur; field ve parametrelerde kullanımı genellikle gereksiz karmaşıklık yaratır, Optional.get yerine orElseThrow, map ve orElseGet tercih edilmelidir.$e$, 16);

CREATE TEMP TABLE java_options (
    question_id varchar(50) NOT NULL REFERENCES java_questions(id),
    text text NOT NULL,
    is_correct boolean NOT NULL,
    sort_order integer NOT NULL,
    PRIMARY KEY (question_id, sort_order)
) ON COMMIT DROP;

INSERT INTO java_options VALUES

('java-001', 'String kullanmaya devam etmek; Java 9+ ile + işlemi invokedynamic üzerinden optimize edildiği için döngüdeki birleştirmeler de tek bir buffer üzerinde yapılır.', false, 0),
('java-001', 'StringBuffer kullanmak; tek thread''de kilit çekişmesi olmadığı için StringBuilder ile performans farkı oluşmaz ve ileride çok thread''e geçişte güvenli kalır.', false, 1),
('java-001', 'Döngü öncesinde bir StringBuilder oluşturup append etmek; + optimizasyonu her ifadeyi ayrı ele aldığı için döngü boyunca kopyalama maliyeti birikir.', true, 2),
('java-001', 'Her satırı result.concat(line) ile eklemek; concat yeni nesne üretmeden mevcut String''in iç dizisini genişlettiği için kopyalama maliyetini ortadan kaldırır.', false, 3),

('java-002', 'Key eklendikten sonra customerId değişmiştir; entry eski hash ile eski bucket''ta kalır, get ise yeni hash ile aradığı için entry''yi bulamaz.', true, 0),
('java-002', 'equals ve hashCode sözleşmesi bozuktur; eşit nesnelerin farklı hashCode üretmesi, keySet''te görünen key''in get ile bulunamamasını açıklar.', false, 1),
('java-002', 'Map büyürken yapılan resize işlemi entry''leri yeni bucket''lara taşır; get çağrısı resize sonrasındaki ilk erişimde geçici olarak null dönebilir.', false, 2),
('java-002', 'Bucket''ta 8''den fazla eleman olunca HashMap tree yapısına geçer; OrderKey Comparable olmadığı için ağaçta arama yapılamaz ve get null döner.', false, 3),

('java-003', 'cache.putIfAbsent(key, buildReport(key)) kullanmak; çağrı atomik olduğu için buildReport aynı key için yalnızca bir kez çalışır.', false, 0),
('java-003', 'get metodunu synchronized yapmak; ConcurrentHashMap ile birlikte kullanıldığında kilit yalnızca ilgili key için alınır ve diğer key''ler beklemez.', false, 1),
('java-003', 'Map''i Collections.synchronizedMap ile sarmak; containsKey ve put art arda çağrıldığında aynı kilit altında tek bir işlem gibi çalışır.', false, 2),
('java-003', 'cache.computeIfAbsent(key, this::buildReport) kullanmak; hesaplama aynı key için bir kez yapılır, ancak süresince ilgili bin kilitli kalır ve fonksiyon içinde map değiştirilmemelidir.', true, 3),

('java-004', 'false / true / true / false', false, 0),
('java-004', 'false / true / true / true', true, 1),
('java-004', 'true / true / true / true', false, 2),
('java-004', 'false / true / false / true', false, 3),

('java-005', 'Sınıf immutable''dır; final alan referansı, unmodifiableList ise içeriği koruduğu için iki önlem birlikte yeterlidir.', false, 0),
('java-005', 'Getter her çağrıda listeyi kopyaladığı için gereksiz maliyetlidir; constructor''da Collections.unmodifiableList(roles) ile bir kez sarmak hem yeterli hem verimlidir.', false, 1),
('java-005', 'Getter dönen listeyi korur, ancak constructor''a verilen liste dışarıda değiştirilebilir; List.copyOf(roles) ile kopya alınmalı ve getter bu listeyi doğrudan dönebilir.', true, 2),
('java-005', 'Constructor''da new ArrayList<>(roles) ile kopya almak yeterlidir; alan final olduğu için getter''daki unmodifiableList sarmalaması kaldırılabilir.', false, 3),

('java-006', 'Primitive değerler stack frame''de tutulur; bu yüzden bir nesnenin int field''ı da nesneyi oluşturan metodun stack frame''inde saklanır.', false, 0),
('java-006', 'Her thread kendi heap bölgesine sahiptir; nesneler yalnızca static alanlar üzerinden paylaşıldığında thread''ler arasında görünür hale gelir.', false, 1),
('java-006', 'Nesneler her koşulda heap''te oluşturulur; JIT''in bir nesneyi escape analysis sonucu heap''e hiç ayırmaması mümkün değildir.', false, 2),
('java-006', 'Her thread''in kendi stack''i vardır ve local değişkenler frame''lerde tutulur; nesneler kavramsal olarak heap''tedir ve primitive field''ları da nesneyle birlikte heap''te yaşar.', true, 3),

('java-007', 'Eksik kolonu domain exception ile bildirmek, IOException''ı cause''u koruyarak sarıp iletmek; OutOfMemoryError''ı yakalamayıp dosyayı streaming ile işleyecek şekilde tasarımı düzeltmek.', true, 0),
('java-007', 'Üç durumu da catch (Exception e) ile yakalayıp ortak bir ImportFailedException''a çevirmek; böylece istemci tek bir hata tipiyle ilgilenir ve akış tutarlı kalır.', false, 1),
('java-007', 'Eksik kolonu checked exception ile bildirmek, IOException''ı RuntimeException''a sarmak; OutOfMemoryError''ı yakalayıp System.gc() çağırarak işleme devam etmek.', false, 2),
('java-007', 'Eksik kolonu domain exception ile bildirmek, IOException''ı loglayıp boş sonuç dönmek; OutOfMemoryError''ı catch (Throwable) ile yakalayıp anlaşılır mesaj göstermek.', false, 3),

('java-008', 'Her katmanda loglamaya devam edip yeni exception''a cause eklemek; root cause korunur ve tekrarlanan loglar tanılama için ek bağlam sağlar.', false, 0),
('java-008', 'Repository ve service''teki catch bloklarını kaldırıp her controller metodunda try/catch ile hatayı yakalamak, loglamak ve response''u orada oluşturmak.', false, 1),
('java-008', 'Yalnızca anlamlı şekilde çevrilebilen katmanda yakalayıp cause''u koruyarak domain exception''a çevirmek; loglamayı ve hata response''unu tek bir @RestControllerAdvice''ta toplamak.', true, 2),
('java-008', 'Teknik exception''ları repository''de yakalayıp yalnızca mesajını yeni bir domain exception''a kopyalamak; stack trace''i loglamamak hassas bilgi sızıntısını önler.', false, 3),

('java-009', 'private alanlara setAccessible(true) ile her koşulda erişilebilir; Java 9+ modül sistemi reflection erişim kurallarını değiştirmemiştir.', false, 0),
('java-009', 'Annotation''lar runtime''da okunabilir; bunun için annotation''ın @Retention(RetentionPolicy.CLASS) ile işaretlenmesi yeterlidir.', false, 1),
('java-009', 'Reflection çağrıları JIT tarafından hiç optimize edilemez; bu yüzden modern framework''ler bean oluştururken reflection''dan tamamen kaçınır.', false, 2),
('java-009', 'Runtime''da metadata okumayı sağlar ve framework''lerde yaygındır; type safety ve bakım maliyeti getirir, Java 9+ modüllerde açılmamış paketlerin private üyelerine erişim kısıtlanır.', true, 3),

('java-010', 'Static alan tüm request thread''leri ve testler arasında tek bir mutable liste paylaştırır; ArrayList senkronize olmadığı için veri kaybı, testlerde de durum sızıntısı oluşur.', true, 0),
('java-010', 'Listeyi Collections.synchronizedList ile sarmak yeterlidir; thread-safety sağlandığında testlerin birbirini etkilemesi de ortadan kalkar.', false, 1),
('java-010', 'Spring bean''leri varsayılan olarak request scope''tadır; static alan her request''te yeniden başlatılır, testlerdeki sorun context cache''inden kaynaklanır.', false, 2),
('java-010', 'Static alanı final yapmak yeterlidir; final referans listeyi thread''ler arasında güvenli şekilde yayınlar ve içeriğin değişmesini engeller.', false, 3),

('java-011', 'LinkedList; elemanlar sırayla bağlı olduğu için iteration CPU cache''inden ArrayList kadar iyi yararlanır ve node başına ek bellek maliyeti ihmal edilebilir.', false, 0),
('java-011', 'ArrayList; index erişimi O(1) ve ardışık bellek düzeni sayesinde iteration cache dostudur, nadir ortadan ekleme/silmenin kopyalama maliyeti çoğunlukla kabul edilebilir.', true, 1),
('java-011', 'LinkedList; ortadan ekleme şimdilik nadir olsa da add(index, e) LinkedList''te O(1) olduğu için ihtiyaç arttığında daha güvenli bir seçimdir.', false, 2),
('java-011', 'ArrayList; ancak iteration için for-each yerine index tabanlı döngü kullanılmalıdır, çünkü ArrayList''in iterator''ı her adımda O(n) maliyet taşır.', false, 3),

('java-012', 'Object.clone() varsayılan olarak deep copy yapar; Address''in paylaşılmasının nedeni Address sınıfının Cloneable''ı uygulamamasıdır.', false, 0),
('java-012', 'Shallow copy yapılmıştır; Person''daki address alanını final yapmak, Address''in iki kopya üzerinden değiştirilmesini engellemek için yeterlidir.', false, 1),
('java-012', 'Deep copy yapılmıştır; ancak city alanı String Pool''dan paylaşıldığı için bir kopyadaki değişiklik diğerine de yansır.', false, 2),
('java-012', 'Shallow copy yapılmıştır; Address ya kopyalama sırasında ayrıca kopyalanmalı ya da immutable yapılıp değişiklik yeni bir Address nesnesiyle ifade edilmelidir.', true, 3),

('java-013', 'Java object''leri pass-by-reference gönderir; replace çağrısından sonra reference değişkeni User("B") nesnesini gösterir.', false, 0),
('java-013', 'Primitive''ler değerle, object''ler referansla aktarılır; ancak metot içinde yeni nesne atandığı için referans bağı kopar ve dış değişken User("A")''da kalır.', false, 1),
('java-013', 'Java her zaman pass-by-value''dur; referansın kopyası aktarılır ve atama yalnızca kopyayı değiştirir. replace yeni User''ı döndürmeli, çağıran taraf atamalıdır.', true, 2),
('java-013', 'Java pass-by-value olduğu için metoda nesnenin kopyası gider; bu nedenle user.setName("B") gibi bir çağrı da dışarıdaki nesneyi etkilemez.', false, 3),

('java-014', 'Erasure tüm generic bilgiyi class dosyasından siler; bu yüzden Jackson''ın TypeReference gibi yöntemleri de tip argümanını runtime''da öğrenemez.', false, 0),
('java-014', 'Bir nesnenin tip argümanı runtime''da bilinmez; ancak field, method ve superclass bildirimlerindeki generic tipler class dosyasında saklanır ve reflection ile okunabilir.', true, 1),
('java-014', 'List<String> ve List<Integer> runtime''da farklı Class nesnelerine sahiptir; erasure yalnızca instanceof ile generic tip kontrolünü engeller.', false, 2),
('java-014', 'Erasure nedeniyle new T() yazılamaz; ancak T.class ile Class nesnesi alınıp reflection üzerinden yeni örnek oluşturulabilir.', false, 3),

('java-015', 'ConcurrentModificationException fırlatılır; "b" enhanced for''un iterator''ı dışında silindiği için döngünün bir sonraki adımında fail-fast kontrol tetiklenir.', false, 0),
('java-015', 'Exception fırlatılmaz ve [a, c] yazdırılır; "b" sondan bir önceki eleman olduğu için silme sonrası hasNext() false döner, "c" hiç ziyaret edilmez.', true, 1),
('java-015', 'ConcurrentModificationException fırlatılır ve "b" silinmez; ArrayList.remove yapısal değişiklikten önce aktif bir iterator olup olmadığını kontrol eder.', false, 2),
('java-015', 'Exception fırlatılmaz ve [a, c] yazdırılır; ArrayList tek thread''de iterator dışındaki silmeyi destekler, fail-fast kontrol yalnızca çok thread''li erişimde çalışır.', false, 3),

('java-016', 'orElse argümanı Optional dolu olsa bile önceden değerlendirilir; repository.load her çağrıda çalışır, yerine orElseGet(() -> repository.load(id)) kullanılmalıdır.', true, 0),
('java-016', 'Optional.ofNullable değeri sararken cache.get''i ikinci kez çağırır; sonuç önce local değişkende tutulup Optional.of ile sarılmalıdır.', false, 1),
('java-016', 'orElse yalnızca Optional boşken çalışır; sorun cache''in null değerleri saklamasıdır, cache değerleri Optional<User> olarak tutulmalıdır.', false, 2),
('java-016', 'repository.load lazy çalışır, ancak sonucu cache''e geri yazılmadığı için her çağrı veritabanına gider; load sonrasına cache.put eklenmelidir.', false, 3);

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
    IF (SELECT count(*) FROM questions WHERE quiz_id = (SELECT quiz_id FROM java_target)) <> 16 THEN
        RAISE EXCEPTION 'Expected exactly sixteen questions in the Java quiz';
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
