('pattern-oop-002', 'İndirim davranışlarını Strategy ile ayırmak, oluşturma kararını uygun bir factory/DI sınırına taşımak ve sipariş state''ini paylaşmamak uygundur; Singleton bu iki sorumluluğun yerine geçmez.', true, 3),
('solid-oop-003', 'Orkestrasyonu kanal ve repository interface''lerine bağlamak, yeni kanalı composition root''ta kaydetmek; teslimat onayını yalnızca destekleyen kanalların uyguladığı ayrı bir yetenek yapıp tüm kanallarda ortak sonuç/hata sözleşmesini korumak.', true, 0),
('solid-oop-003', 'Her kanal sınıfı için bir interface tanımlayıp NotificationService''e constructor ile enjekte etmek; kanal seçimindeki if/else ve SQL sorgularını servis içinde tutmak, çünkü bağımlılıklar artık soyutlamaya bağlıdır.', false, 1),
('solid-oop-003', 'Kanalları send(), confirmDelivery() ve refund() içeren ortak bir interface''e bağlamak; teslimat onayını desteklemeyen kanallarda confirmDelivery()''yi boş bırakıp yeni kanalları composition root''ta kaydetmek.', false, 2),
('solid-oop-003', 'Kanalları ortak bir abstract class''tan türetip yeni kanalları dışarıda kaydetmek; provider farklılıklarını subclass''lara bırakıp başarılı send() dönüşünü tüm kanallarda kesin teslimat olarak yorumlamak.', false, 3),
('abstract-oop-004', 'Audit kodunu paylaşmak için ortak bir abstract Validator tanımlamak; SDK sınıflarını mevcut base class''larından ayırıp bu abstract class''tan türetecek şekilde yeniden düzenlemek.', false, 0),
('abstract-oop-004', 'Validator interface''ine default audit metodu eklemek; audit''in ihtiyaç duyduğu logger ve sayaç gibi state''i de interface''te tanımlayıp tüm implementasyonların bu alanları paylaşmasını sağlamak.', false, 1),
('abstract-oop-004', 'Bağımsız implementasyonları Validator interface''iyle birleştirmek, SDK''ları adapter ile sarmak ve audit''i decorator ile paylaşmak; abstract class''ı yalnızca gerçek bir ortak temel gerektiğinde kullanmak.', true, 2),
('abstract-oop-004', 'Validator interface''ini tanımlayıp SDK''ları adapter ile sarmak; audit davranışını ise istemcide, validator''ın concrete tipine göre instanceof ile seçilen yardımcı metotlarla uygulamak.', false, 3),
('abstraction-oop-005', 'instanceof kontrollerini istemciden alıp ayrı bir PaymentGatewayHelper sınıfına taşımak; böylece sağlayıcı ayrıntıları istemci kodunda görünmez ve interface''in sunduğu soyutlama korunur.', false, 0),
('abstraction-oop-005', 'Giriş, sonuç ve hata sözleşmesini iş ihtiyacına göre tanımlamak; sağlayıcıya özgü çeviriyi adapter''larda tutmak ve yalnızca bazı sağlayıcıların desteklediği yetenekleri ortak sözleşmeye eklememek.', true, 1),
('abstraction-oop-005', 'Ortak ödeme metotlarını sözleşmede tutmak; sağlayıcıya özgü alanları da PaymentGateway''e opsiyonel getter olarak ekleyip istemcinin cast yapmadan bu ayrıntılara erişmesini sağlamak.', false, 2),
('abstraction-oop-005', 'Sağlayıcıları ortak bir abstract PaymentGateway sınıfından türetip tekrar eden kodu bu sınıfa taşımak; istemcideki sağlayıcı tipi kontrollerini ise geriye dönük uyumluluk için korumak.', false, 3),
('inheritance-oop-006', 'Mevcut hiyerarşiyi korumak; artan sınıf sayısını, istenen biçim ve seçenek kombinasyonuna göre doğru subclass''ı seçen bir factory ile istemciden gizlemek.', false, 0),
('inheritance-oop-006', 'Sıkıştırma ve şifrelemeyi ara base class''lara taşımak; böylece tekrar eden kod azalır ve her biçim ihtiyaç duyduğu davranışları kalıtım zinciri üzerinden devralır.', false, 1),
('inheritance-oop-006', 'Hiyerarşiyi tek bir Exporter sınıfında birleştirmek; sıkıştırma ve şifrelemeyi constructor''dan alınan flag''lerle açıp kapatmak ve uygulama sırasını sınıf içinde sabitlemek.', false, 2),
('inheritance-oop-006', 'Export biçimini ayrı bir sözleşmeyle tanımlamak; sıkıştırma ve şifrelemeyi sırası açıkça belirlenen decorator''larla birleştirmek ve kalıtımı stabil is-a ilişkileriyle sınırlamak.', true, 3),
('polymorphism-oop-007', 'Derived:Object / Base:String / Base', true, 0),
('polymorphism-oop-007', 'Base:Object / Base:String / Base', false, 1),
('polymorphism-oop-007', 'Base:String / Base:String / Derived', false, 2),
('polymorphism-oop-007', 'Derived:Object / Base:String / Derived', false, 3),
('encapsulation-oop-008', 'Constructor''da List.copyOf ile liste alias''ını kesmek ve status''ü enum yapmak; durum geçişleri için genel setStatus metodunu korumak, çünkü enum yalnızca geçerli değerlerin atanmasına izin verir.', false, 0),
('encapsulation-oop-008', 'Liste elemanlarını immutable yapmak ve confirm() içinde boş liste kontrolü eklemek; constructor''a verilen listeyi doğrudan saklamaya ve DRAFT''a dönüş için setter''ı tutmaya devam etmek.', false, 1),
('encapsulation-oop-008', 'Listeyi kopyalayıp dışarıya immutable görünüm sunmak; confirm() içinde DRAFT ve dolu liste koşullarını doğrulamak, düzenlemeyi DRAFT''ta çalışan domain metotlarına bırakıp genel status setter''ını kaldırmak.', true, 2),
('encapsulation-oop-008', 'Liste kopyalama ve durum kontrollerini controller katmanında yapmak; Order''ı private alanlar ve getter/setter''larla tutmak, çünkü bütün değişiklikler zaten bu controller üzerinden gelir.', false, 3),
('singleton-oop-009', 'getInstance()''ı lazy ve double-checked locking ile thread-safe yapmak; böylece paylaşılan Metrics nesnesi güvenle kullanılır ve testlerde ayrıca bir düzenlemeye gerek kalmaz.', false, 0),
('singleton-oop-009', 'Metrics''i constructor ile enjekte edip global getInstance() bağımlılığını kaldırmak; tekil ömrü DI container''daki scope ile yönetmek ve paylaşılan mutable state''i ayrıca senkronize etmek.', true, 1),
('singleton-oop-009', 'Testlerde getInstance()''ın döndürdüğü nesneyi reflection ile sahte bir Metrics''le değiştirmek; global erişimi koruyup her testten sonra instance''ı sıfırlayan bir yardımcı metot eklemek.', false, 2),
('singleton-oop-009', 'Metrics''i constructor ile enjekte edip DI container''da singleton scope vermek; container nesneyi bir kez oluşturduğu için içindeki sayaçlar ek senkronizasyon olmadan güvenle paylaşılır.', false, 3),
('srpocpdip-oop-010', 'SmtpMailer''ı constructor ile enjekte etmeye devam etmek; yeni biçim ve kanal ihtiyaçlarını InvoiceService içindeki switch bloklarına eklemek, çünkü bağımlılık artık dışarıdan veriliyor.', false, 0),
('srpocpdip-oop-010', 'Hesaplama, PDF üretimi ve gönderimi ayrı sınıflara taşımak; bu sınıfları SMTP host ve port ayarlarını da içeren ortak bir InvoiceChannel interface''ine bağlamak.', false, 1),
('srpocpdip-oop-010', 'PDF üretimi ve SMTP gönderimini tek bir InvoiceStrategy''de toplamak; yeni kanal geldiğinde bu strategy''ye yeni bir dal eklemek, böylece ilgili kod tek yerde kalır.', false, 2),
('srpocpdip-oop-010', 'Hesaplama, sunum ve teslimat değişim nedenlerini ayırmak; renderer ve delivery sözleşmelerini iş ihtiyacına göre tanımlayıp adapter''ları bunlara bağlamak ve implementasyonları composition root''ta seçmek.', true, 3),
('lsp-oop-011', 'İki subclass da sözleşmeyi bozar: minimum tutar önkoşulu güçlendirir, ek ücret ise bakiyenin tam amount kadar azalması sonkoşulunu karşılamaz; kurallar ayrı bir policy ile modellenmelidir.', true, 0),
('lsp-oop-011', 'Yalnızca minimum tutar ekleyen subclass sözleşmeyi bozar; ek ücret bakiyeyi aynı yönde azalttığı için üst sınıfın sonkoşulunu güçlendirir ve LSP''ye uygundur.', false, 1),
('lsp-oop-011', 'Yalnızca ek ücret alan subclass sözleşmeyi bozar; minimum tutar kontrolü yalnızca anlamsız girdileri reddettiği için önkoşulu daraltmaz ve LSP''ye uygundur.', false, 2),
('lsp-oop-011', 'İki subclass da uygundur; method signature aynı kaldığı ve reddedilen işlemler belgelenmiş bir exception ile bildirildiği sürece LSP korunur.', false, 3),
('isp-oop-012', 'DocumentStore''u korumak; ReadOnlyArchive''da write, delete ve watch için UnsupportedOperationException fırlatan metotlar tanımlayıp bu davranışı Javadoc''ta belgelemek.', false, 0),
('isp-oop-012', 'İstemcileri yalnızca ihtiyaç duydukları reader, writer ve watch yetenek interface''lerine bağlamak; ReadOnlyArchive yalnızca reader''ı, tam sağlayıcılar gereken interface''lerin hepsini uygulasın.', true, 1),
('isp-oop-012', 'DocumentStore''a canWrite(), canDelete() ve canWatch() sorgularını eklemek; istemciler işlemden önce sağlayıcının yeteneğini kontrol ederek desteklenmeyen çağrılardan kaçınsın.', false, 2),
('isp-oop-012', 'ReadOnlyArchive''da desteklenmeyen işlemleri hata fırlatmadan no-op olarak uygulamak; geniş interface korunur ve mevcut istemciler değişiklik gerektirmeden çalışmaya devam eder.', false, 3),
('abstract-oop-013', 'Mevcut kod acme döndürür; superclass metodu kaldırılırsa implements listesinde ilk sıradaki interface''in default metodu seçilir ve kod left döndürür.', false, 0),
('abstract-oop-013', 'Mevcut kod derlenmez; aynı signature''a sahip iki default metot, superclass''ta concrete bir implementasyon olsa bile çakışır ve Validator''da açık override gerekir.', false, 1),
('abstract-oop-013', 'Mevcut kod acme döndürür; concrete superclass metodu kaldırılırsa ilgisiz iki default metot çakışır ve Validator açık override yazmadan derlenmez.', true, 2),
('abstract-oop-013', 'Mevcut kod derlenmez; superclass metodu final olduğu için interface''lerdeki aynı signature''lı default metotlarla birlikte bulunamaz.', false, 3),
('polymorphism-oop-014', 'Child / Child; private Parent.label Child''da override edilir ve dinamik bağlanır, @Override eklemek bu ilişkiyi derleyiciye doğrulatır.', false, 0),
('polymorphism-oop-014', 'Parent / Parent; render final olduğu için Child üzerindeki tüm instance çağrıları Parent implementasyonlarına statik bağlanır.', false, 1),
('polymorphism-oop-014', 'Parent / Child; Child.label private Parent.label''ı override etmez ve @Override eklemek hatadır, ancak public final render Child''da aynı signature ile yeniden tanımlanarak gizlenebilir.', false, 2),
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

-- Preserve existing question content except the explicitly expanded encapsulation scenario.
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

-- Refresh option wording for every seeded OOP question (correct-answer positions are unchanged).
UPDATE options o
SET text = s.text, is_correct = s.is_correct
FROM oop_options s
JOIN questions q ON q.id = s.question_id
WHERE o.question_id = s.question_id AND o.sort_order = s.sort_order
  AND q.quiz_id = (SELECT quiz_id FROM oop_target)
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
