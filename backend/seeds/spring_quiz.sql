-- Spring ve Spring Boot quiz seed
-- 24 senaryo tabanlı soru: Java Mülakat Notları'ndaki Spring ve Spring Boot bölümünün 12 sorusu x 2 varyant.
-- Aynı konunun iki varyantı aynı sort_order değerini paylaşır (ör. spring-001 ve spring-001b).
-- Uygulama, her sort_order grubundan rastgele bir soru seçerek 12 soruluk bir sınav oluşturmalıdır.
-- Run explicitly against an existing database; this is not a schema migration.

BEGIN;

INSERT INTO categories (name, slug, description)
VALUES ('Spring ve Spring Boot', 'spring', 'Spring IoC container, bean yaşam döngüsü, Spring Boot auto-configuration, Spring MVC ve @Transactional')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO quizzes (id, title, description, category_id, time_limit_seconds, passing_score)
SELECT '8e4b2f6a-1c7d-4a93-b5e8-3f9d6c2a7b15', 'Spring ve Spring Boot',
       'Senior mülakat: Spring ve Spring Boot üzerine 12 senaryo.',
       id, 2400, 70
FROM categories
WHERE slug = 'spring'
  AND NOT EXISTS (SELECT 1 FROM quizzes WHERE category_id = categories.id AND title = 'Spring ve Spring Boot');

CREATE TEMP TABLE spring_target ON COMMIT DROP AS
SELECT q.id::varchar(50) AS quiz_id
FROM quizzes q
JOIN categories c ON c.id = q.category_id
WHERE c.slug = 'spring' AND q.title = 'Spring ve Spring Boot';

DO $$
BEGIN
    IF (SELECT count(*) FROM spring_target) <> 1 THEN
        RAISE EXCEPTION 'Expected exactly one Spring quiz';
    END IF;
END;
$$;

UPDATE quizzes
SET description = 'Senior mülakat: Spring ve Spring Boot üzerine 12 senaryo.',
    time_limit_seconds = 2400
WHERE id::text = (SELECT quiz_id FROM spring_target);

CREATE TEMP TABLE spring_questions (
    id varchar(50) PRIMARY KEY,
    text text NOT NULL,
    code_snippet text NOT NULL,
    explanation text NOT NULL,
    sort_order integer NOT NULL
) ON COMMIT DROP;

INSERT INTO spring_questions VALUES

-- 1. ApplicationContext ----------------------------------------------------

('spring-001',
$q$Bir ödeme servisinde PaymentGatewayClient bean'i, constructor'ında zorunlu API anahtarının tanımlı olup olmadığını kontrol ediyor. Anahtar yanlışlıkla tanımlanmadan deploy edilince uygulama açılışta hata verip duruyor. Bir geliştirici, "Uygulama yine de ayağa kalksın, hata ilk ödeme isteğinde alınsın" diyerek bean'e @Lazy eklemeyi öneriyor. Bu öneriyle ilgili en doğru değerlendirme hangisidir?$q$,
$code$@Component
public class PaymentGatewayClient {

    public PaymentGatewayClient(@Value("${payment.api-key:}") String apiKey) {
        if (apiKey.isBlank()) {
            throw new IllegalStateException("payment.api-key tanımlı değil");
        }
        // ...
    }
}$code$,
$e$ApplicationContext, singleton bean'leri varsayılan olarak uygulama açılırken oluşturur. Bu sayede eksik konfigürasyon, hatalı bağımlılık gibi sorunlar deploy anında ortaya çıkar ve hatalı sürüm trafik almadan durdurulur; bu bir kusur değil, ApplicationContext'in BeanFactory'ye göre sunduğu bir avantajdır. @Lazy hatayı ortadan kaldırmaz, yalnızca ilk ödeme isteğine erteler: uygulama sağlıklı görünür, health check geçer ve hata gerçek bir müşteri işleminde patlar. Bean'leri istendiğinde oluşturan temel davranış BeanFactory'ye aittir, ApplicationContext'e değil. Bean'i prototype yapmak da hatayı gizler ve her istekte nesneyi yeniden oluşturarak yeni bir maliyet ekler.$e$, 1),

('spring-001b',
$q$Bir geliştirici, hızlı çalışan bir test için Spring context'i ayağa kaldırmak yerine bean tanımlarını bir DefaultListableBeanFactory'ye elle kaydediyor. Bean'ler oluşuyor; ancak @Autowired ile işaretli alanlar null kalıyor ve @Transactional metotlar transaction açmıyor. Uygulamanın kendisinde ise her şey çalışıyor. Bu farkın nedeni nedir?$q$,
$code$DefaultListableBeanFactory factory = new DefaultListableBeanFactory();
factory.registerBeanDefinition("orderService",
        new RootBeanDefinition(OrderService.class));
factory.registerBeanDefinition("orderRepository",
        new RootBeanDefinition(InMemoryOrderRepository.class));

OrderService service = factory.getBean(OrderService.class);$code$,
$e$@Autowired ile enjeksiyon, @Transactional için proxy oluşturma ve @PostConstruct gibi davranışlar container'ın çekirdeğinde değil, BeanPostProcessor'larda uygulanır (ör. AutowiredAnnotationBeanPostProcessor, transaction altyapısının kaydettiği auto-proxy creator). Spring Boot'un ve AnnotationConfigApplicationContext gibi annotation tabanlı context'lerin kurulumu bu post-processor altyapısını kaydeder; çıplak bir DefaultListableBeanFactory bunu kendiliğinden yapmaz, bu yüzden bunların elle eklenmesi gerekir. Bu yüzden annotation'lar yerinde durur ama onları işleyecek bir şey yoktur. Annotation'ların görünürlüğü container tipine bağlı değildir; @Autowired ve @Transactional RUNTIME retention'a sahiptir. @ComponentScan de bir annotation'dır; onu işleyen, annotation tabanlı context'in kaydettiği ConfigurationClassPostProcessor'dır. Lazy oluşturma ise post-processor'ların hiç çalışmamasını açıklamaz.$e$, 1),

-- 2. Bean yaşam döngüsü ----------------------------------------------------

('spring-002',
$q$Bir katalog servisi, uygulama açılırken ürünleri önbelleğe almak için aşağıdaki bean'i kullanıyor. loadAll metodu lazy yüklenen kategori ilişkisine eriştiğinde LazyInitializationException alınıyor; loglar, metodun bir transaction içinde çalışmadığını gösteriyor. Nedeni ve doğru çözüm hangisidir?$q$,
$code$@Service
public class CatalogCacheWarmer {

    private final ProductRepository productRepository;

    public CatalogCacheWarmer(ProductRepository productRepository) {
        this.productRepository = productRepository;
    }

    @PostConstruct
    public void init() {
        loadAll();
    }

    @Transactional(readOnly = true)
    public void loadAll() {
        productRepository.findAll()
                .forEach(p -> cache.put(p.getId(), p.getCategory().getName()));
    }
}$code$,
$e$Burada iki neden üst üste biner. Birincisi, @PostConstruct init callback'leri, AOP proxy'lerinin oluşturulduğu postProcessAfterInitialization adımından önce, ham nesne üzerinde çalışır. İkincisi, init içindeki loadAll() çağrısı this üzerinden yapılır ve proxy'yi hiç görmez (self-invocation). Bu yüzden @Transactional yok sayılır. Çözüm, işi proxy'nin devrede olduğu bir noktaya taşımaktır: transaction'ı TransactionTemplate ile programatik olarak açmak ya da ısınma işini uygulama hazır olduktan sonra (ör. ApplicationReadyEvent) başka bir bean'in, bu bean'in proxy'si üzerinden çağırması. readOnly = true transaction açmayı engellemez; yalnızca bir optimizasyon ipucudur. @PostConstruct'ı çağıran Spring'dir, JVM değil. @Transactional'ı sınıf seviyesine taşımak this çağrısını proxy'den geçirmez.$e$, 2),

('spring-002b',
$q$Bir dosya işleme servisinde, her iş için ayrı bir geçici çalışma alanı açan prototype bir bean kullanılıyor. Bean, @PreDestroy metodunda geçici dosyaları siliyor. Uygulama birkaç gün çalıştıktan sonra diskin silinmeyen geçici dosyalarla dolduğu görülüyor. Nedeni nedir?$q$,
$code$@Component
@Scope("prototype")
public class Workspace {

    private final Path dir = Files.createTempDirectory("job-");

    @PreDestroy
    public void cleanUp() throws IOException {
        FileSystemUtils.deleteRecursively(dir);
    }
}

// Kullanım
Workspace ws = workspaceProvider.getObject();
process(job, ws);$code$,
$e$Spring bir prototype bean'i oluşturur, bağımlılıklarını enjekte eder, init callback'lerini çağırır ve nesneyi isteyene teslim eder; bundan sonra o nesneyi takip etmez. Bu yüzden prototype bean'lerde @PreDestroy veya DisposableBean.destroy hiçbir zaman çağrılmaz, context kapanırken bile. Kaynağı serbest bırakma sorumluluğu nesneyi alan koddadır: Workspace AutoCloseable yapılıp try-with-resources ile kullanılabilir. Garbage collector destroy callback'lerini çağırmaz; DisposableBean'e geçmek de bir şey değiştirmez. Prototype bean'in bir singleton'a enjekte edilmesi de Spring'in onu takip etmesini sağlamaz.$e$, 2),

-- 3. IoC, DI ve Spring'in temel bileşenleri --------------------------------

('spring-003',
$q$Bir mimari tartışmada bir geliştirici "IoC ile Dependency Injection aynı şeydir" diyor. Aşağıdakilerden hangisi, Dependency Injection olmadığı halde Inversion of Control'e bir örnektir?$q$,
'',
$e$IoC, akışın kontrolünün uygulama kodundan bir framework'e veya container'a devredilmesidir: "Sen beni çağırma, ben seni çağırırım." DI, bu prensibin bağımlılık yönetimine uygulanmış halidir ve IoC'nin tek örneği değildir. JdbcTemplate'te bağlantıyı açmak, sorguyu çalıştırmak, hataları çevirmek ve kaynakları kapatmak framework'tedir; uygulama yalnızca satır eşleme callback'ini verir ve onu framework çağırır. Bu, DI olmadan bir IoC örneğidir (template callback); event listener'lar da benzer bir örnektir. Bağımlılığı constructor parametresi olarak almak DI'dır. Bağımlılığı bir service locator'dan istemek ya da new ile oluşturmak ise kontrolü sınıfın kendisinde bırakır; bunlar IoC değildir.$e$, 3),

('spring-003b',
$q$Bir ekip, loglama, transaction yönetimi ve yetki kontrolünü yüzlerce servis metoduna tek tek yazmak yerine merkezi bir yerden yönetmek istiyor. Servis sınıflarının bu konulardan habersiz kalması da bir gereksinim. Spring'in hangi bileşeni ve mekanizması bu ihtiyacı karşılar?$q$,
'',
$e$Loglama, transaction ve güvenlik gibi birçok modülü yatay kesen konular (cross-cutting concerns) Spring AOP ile çözülür. Bu davranışlar bir aspect olarak bir kez tanımlanır; Spring ilgili bean'leri proxy ile sarar ve metot çağrılarının önüne ve arkasına bu davranışı ekler. @Transactional, @Cacheable, @Async ve method security de bu mekanizmayla çalışır. HandlerInterceptor yalnızca Spring MVC'deki web isteklerini görür; servisler arası metot çağrılarını yakalamaz. BeanFactoryPostProcessor bean tanımlarını (metadata) değiştirir, metotların etrafına davranış eklemez. Spring her metot çağrısında kendiliğinden event yayınlamaz.$e$, 3),

-- 4. Spring Boot'un avantajları --------------------------------------------

('spring-004',
$q$Spring Boot'a geçiş yapan bir ekipte, Spring Boot'un ne olduğu konusunda dört farklı görüş dile getiriliyor. Hangisi doğrudur?$q$,
'',
$e$Spring Boot, Spring Framework'ün yerine geçmez; onun üzerine bir katman ekler. IoC container, AOP, MVC ve transaction altyapısı yine Spring Framework'tür. Boot'un katkısı; classpath'e ve property'lere göre bean tanımlayan auto-configuration, uyumlu bağımlılık sürümlerini getiren starter'lar, uygulamanın içinde gelen embedded server, profiller ve @ConfigurationProperties ile dış konfigürasyon ve Actuator ile production izlemesidir. Auto-configuration runtime'da koşullara bakarak çalışır, derleme zamanında kod üretmez; GraalVM native image için yapılan AOT işleme ayrı bir özelliktir. Embedded server kullanmak bir zorunluluk değildir: SpringBootServletInitializer ile uygulama harici bir servlet container'a WAR olarak da deploy edilebilir.$e$, 4),

('spring-004b',
$q$Bir ekip, test, staging ve production ortamlarındaki veritabanı adresi ve şifresi farklı olduğu için her ortam için ayrı bir jar üretiyor ve değerleri her jar'ın içindeki application.yml'e yazıyor. Bu yüzden production'a, test edilenden farklı bir artifact çıkıyor. En doğru yaklaşım hangisidir?$q$,
'',
$e$Doğru yaklaşım "bir kez derle, her yerde çalıştır" ilkesidir: tek bir artifact üretilir ve test edilen jar'ın aynısı production'a çıkar. Genel ve varsayılan konfigürasyon artifact'in içinde bulunabilir; ortama özgü değerler ise environment variable'lar, jar dışındaki konfigürasyon dosyaları, Config Server veya bir secret yöneticisi gibi dış kaynaklardan verilir ve varsayılanları ezer. Jar'ın içine gömülen application-prod.yml gibi profil dosyaları da artifact'in parçasıdır; bu tek başına kötü değildir, ama ortama özgü ve gizli değerlerin dışarıdan gelmesi asıl önemli olandır. Spring Boot bu kaynakları bir öncelik sırasıyla birleştirir; environment variable'lar (ör. SPRING_DATASOURCE_PASSWORD) jar içindeki application.yml'deki değeri ezer. Şifreler gibi gizli değerler artifact'e gömülmez, secret yönetimiyle verilir. @Profile ile her ortam için kodda ayrı bean yazmak, sadece değerleri farklı olan bir durumu gereksiz yere koda taşır.$e$, 4),

-- 5. Auto-configuration ----------------------------------------------------

('spring-005',
$q$Bir ekip, veritabanı bağlantısını özelleştirmek için kendi DataSource bean'ini tanımlıyor. Ardından application.yml'e spring.datasource.hikari.maximum-pool-size: 50 ekliyor; ancak izleme ekranında havuz boyutunun hâlâ 10 olduğu görülüyor. Nedeni nedir?$q$,
$code$@Configuration
public class DataSourceConfig {

    @Bean
    public DataSource dataSource() {
        HikariDataSource ds = new HikariDataSource();
        ds.setJdbcUrl("jdbc:postgresql://db:5432/orders");
        ds.setUsername("app");
        ds.setPassword(System.getenv("DB_PASSWORD"));
        return ds;
    }
}$code$,
$e$DataSourceAutoConfiguration, DataSource bean'ini @ConditionalOnMissingBean koşuluyla tanımlar: kullanıcı aynı tipte bir bean tanımladıysa auto-configuration geri çekilir. spring.datasource.hikari.* property'lerini HikariDataSource'a bağlayan da bu auto-configuration'dır. Kendi bean'inizi new ile oluşturduğunuzda bu bağlama yapılmaz ve HikariCP kendi varsayılanı olan 10'luk havuzla çalışır. Çözüm, ya kendi bean'i kaldırıp ayarları property'lerle vermek ya da bean metoduna @ConfigurationProperties("spring.datasource.hikari") ekleyerek property'leri elle oluşturulan nesneye bağlatmaktır. Auto-configuration kullanıcının bean'ini ezmez; tam tersine ona yol verir. Spring Boot 3'te auto-configuration kaydı için spring.factories kullanılmaz; bu durumla da ilgisi yoktur.$e$, 5),

('spring-005b',
$q$Şirket içi bir starter kütüphanesi, auto-configuration sınıfını META-INF/spring.factories dosyasında EnableAutoConfiguration anahtarıyla kaydediyor. Servisler Spring Boot 2.7'den 3.2'ye yükseltildikten sonra bu kütüphanenin tanımladığı bean'ler oluşmuyor ve uygulama ilgili bağımlılığı bulamadığı için açılmıyor. Nedeni ve doğru çözüm hangisidir?$q$,
$code$# META-INF/spring.factories
org.springframework.boot.autoconfigure.EnableAutoConfiguration=\
  com.acme.audit.AuditAutoConfiguration$code$,
$e$Auto-configuration sınıflarının spring.factories dosyasında EnableAutoConfiguration anahtarıyla kaydedilmesi Spring Boot 2.7'de deprecated oldu ve 3.0'da kaldırıldı. Boot 3, aday auto-configuration'ları yalnızca META-INF/spring/org.springframework.boot.autoconfigure.AutoConfiguration.imports dosyasından okur. Çözüm, sınıfı bu dosyaya yazmak ve @AutoConfiguration ile işaretlemektir. Hangi auto-configuration'ın neden uygulandığı ya da uygulanmadığı --debug ile basılan condition evaluation report'ta veya /actuator/conditions endpoint'inde görülebilir. spring.factories başka genişletme noktaları (ör. EnvironmentPostProcessor) için hâlâ kullanılır, ama auto-configuration kaydı için kullanılmaz. Kütüphane sınıflarını uygulamanın paketine taşıyıp component scan'e bırakmak, koşullu yükleme ve sıralama gibi auto-configuration özelliklerini kaybettirir. @ConditionalOnClass Boot 3'te de vardır.$e$, 5),

-- 6. Spring'deki design pattern'lar ----------------------------------------

('spring-006',
$q$Bir ürün servisinde getProduct metodu @Cacheable ile işaretli. Controller'dan doğrudan çağrıldığında önbellek çalışıyor; ancak aynı sınıftaki getProducts metodu üzerinden çağrıldığında her seferinde veritabanına gidildiği görülüyor. Bu davranışın arkasındaki Spring tasarım kalıbı ve sonucu hangisidir?$q$,
$code$@Service
public class ProductService {

    @Cacheable("products")
    public Product getProduct(Long id) {
        return productRepository.findById(id).orElseThrow();
    }

    public List<Product> getProducts(List<Long> ids) {
        return ids.stream().map(this::getProduct).toList();
    }
}$code$,
$e$@Cacheable, @Transactional ve @Async gibi annotation'lar Proxy kalıbıyla çalışır: Spring bean'i bir proxy ile sarar ve önbellek kontrolü bu proxy'de yapılır. Controller, ProductService'in proxy'sini çağırdığı için önbellek devreye girer. getProducts içindeki this::getProduct çağrısı ise nesnenin kendisine yapılır, proxy'yi atlar (self-invocation) ve önbellek hiç kontrol edilmez. Çözüm, önbellekli metodu başka bir bean'e taşımak veya çağrıyı proxy üzerinden yapmaktır. Template Method JdbcTemplate gibi sabit akış ve callback yapılarında, Observer ApplicationEvent'lerde kullanılır; bu davranışı açıklamazlar. Singleton scope'ta aynı sınıftan yapılan çağrı ikinci bir instance oluşturmaz.$e$, 6),

('spring-006b',
$q$Bir döviz servisi, birincil ve yedek sağlayıcı için aynı sınıftan iki bean tanımlıyor. Kod incelemesinde bir geliştirici, "Spring bean'leri singleton'dır, aynı sınıftan iki nesne oluşması bir hatadır" diyor. Bu yorumla ilgili en doğru değerlendirme hangisidir?$q$,
$code$@Configuration
public class RateClientConfig {

    @Bean
    public ExchangeRateClient primaryRateClient() {
        return new ExchangeRateClient("https://rates.primary.example");
    }

    @Bean
    public ExchangeRateClient backupRateClient() {
        return new ExchangeRateClient("https://rates.backup.example");
    }
}$code$,
$e$Spring'in singleton scope'u, GoF Singleton kalıbıyla aynı şey değildir. GoF Singleton, bir sınıftan JVM'de (class loader başına) tek nesne olmasını sınıfın kendisi garanti eder. Spring singleton ise bean tanımı başına ve container başına tek instance demektir: primaryRateClient ve backupRateClient iki ayrı bean tanımıdır, her biri kendi tek instance'ına sahiptir. Bu yüzden aynı sınıftan iki nesne olması beklenen bir durumdur; enjeksiyon sırasında hangisinin kullanılacağı @Qualifier veya @Primary ile belirtilir. Spring açılışta aynı tipte iki bean'i engellemez; belirsizlik ancak tek bir bean beklenen bir enjeksiyon noktasında hata verir. Singleton thread başına bir kopya anlamına gelmez ve @Bean metotlarının varsayılan scope'u da singleton'dır.$e$, 6),

-- 7. DispatcherServlet ve istek akışı --------------------------------------

('spring-007',
$q$Bir API'de iki gereksinim var: (1) Spring Security tarafından reddedilenler ve statik dosya istekleri dahil her isteğe bir correlation id atanacak ve yanıt başlığına yazılacak. (2) Controller'a ulaşan isteklerde hangi controller metodunun çalıştığı ve ne kadar sürdüğü loglanacak. Bu iki iş için en doğru yerleşim hangisidir?$q$,
'',
$e$Servlet filter'ları DispatcherServlet'ten önce, Servlet seviyesinde çalışır ve her isteği görür; Spring Security'nin kendisi de bir filter zinciridir. Correlation id'nin Security tarafından reddedilen istekler dahil her istekte bulunması gerektiği için, Security zincirinden önce sıralanan bir filter'da üretilmesi gerekir. HandlerInterceptor ise Spring MVC'nin içindedir ve DispatcherServlet handler'ı bulduktan sonra çalışır; preHandle ve afterCompletion'da hangi controller metodunun (HandlerMethod) çalıştığını bilir. Controller metodu bazında süre ve isim loglamak için doğru yer burasıdır. Interceptor, Security'nin reddettiği istekleri hiç görmez. @RestControllerAdvice yalnızca exception'ları ve body dönüşümünü ele alır; her isteği yakalamaz.$e$, 7),

('spring-007b',
$q$Bir sipariş API'sine aşağıdaki gövdeyle istek gönderiliyor ve istemci 400 Bad Request alıyor. Controller metodunun ilk satırındaki log ise hiç yazılmıyor. Bunun nedeni nedir?$q$,
$code$public record CreateOrderRequest(
        @NotNull Long customerId,
        @Positive int quantity) {
}

@PostMapping("/orders")
public OrderResponse create(@Valid @RequestBody CreateOrderRequest request) {
    log.info("create çağrıldı");
    return orderService.create(request);
}

// İstek gövdesi
// { "customerId": null, "quantity": 0 }$code$,
$e$DispatcherServlet isteğe uygun handler'ı bulduktan sonra HandlerAdapter, controller metodunun parametrelerini çözer. @RequestBody için HttpMessageConverter (Jackson) JSON'ı CreateOrderRequest nesnesine çevirir; parametrede @Valid olduğu için nesne hemen ardından Bean Validation ile doğrulanır. customerId null ve quantity pozitif olmadığı için doğrulama başarısız olur ve MethodArgumentNotValidException fırlatılır. Bu, controller metodu çağrılmadan olur; bu yüzden log yazılmaz. Exception, HandlerExceptionResolver tarafından 400'e çevrilir ve yanıt @RestControllerAdvice içindeki bir @ExceptionHandler ile özelleştirilebilir. Spring Security filter'ları gövdenin içeriğini doğrulamaz. preHandle @Valid annotation'ını işlemez. @RestController'da dönüş değeri ViewResolver ile değil HttpMessageConverter ile yazılır.$e$, 7),

-- 8. Annotation'lar --------------------------------------------------------

('spring-008',
$q$Bir gece çalışan rapor işinde, bir geliştirici ReportService'i Spring'den almak yerine new ile oluşturuyor. ReportService'teki generate metodu @Transactional ile işaretli olmasına rağmen, iş yarıda hata verdiğinde yapılan kayıtların geri alınmadığı görülüyor. Nedeni nedir?$q$,
$code$@Component
public class NightlyReportJob {

    private final ReportRepository reportRepository;

    // ...

    @Scheduled(cron = "0 0 2 * * *")
    public void run() {
        ReportService service = new ReportService(reportRepository);
        service.generate(LocalDate.now().minusDays(1));
    }
}$code$,
$e$Annotation, koda eklenen metadata'dır ve kendi başına davranış taşımaz; onu okuyup bir şey yapan bir mekanizma gerekir. @Transactional'ın davranışa dönüşmesi, Spring'in bean'i bir proxy ile sarmasıyla olur ve transaction'ı bu proxy açar. new ile oluşturulan ReportService container'ın dışındadır: proxy'lenmez, generate doğrudan nesnenin kendisinde çalışır ve annotation hiçbir şey yapmaz. Çözüm, ReportService'i bir bean olarak tanımlayıp NightlyReportJob'a enjekte etmektir. @Transactional'ın retention'ı RUNTIME'dır; annotation'lar sınıf yeniden derlenmeden de okunabilir. @Transactional @Service, @Component veya başka herhangi bir bean'de çalışır; yalnızca @Repository'ye özgü değildir.$e$, 8),

('spring-008b',
$q$Bir ekip, kritik işlemleri denetim kaydına yazmak için @Audited adında kendi annotation'ını tanımlıyor ve servis metotlarına ekliyor. Annotation'ın retention'ı RUNTIME, metotlar public ve servisler Spring bean'i; ancak hiçbir denetim kaydı oluşmuyor. Nedeni nedir?$q$,
$code$@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.METHOD)
public @interface Audited {
    String action();
}

@Service
public class AccountService {

    @Audited(action = "CLOSE_ACCOUNT")
    public void closeAccount(Long accountId) { ... }
}$code$,
$e$Annotation yalnızca metadata'dır: RUNTIME retention, onun reflection ile okunabilmesini sağlar ama kimsenin onu okuyacağını garanti etmez. @Transactional veya @Cacheable'ın çalışmasının nedeni annotation'ın kendisi değil, Spring'in bu annotation'ları arayıp ilgili bean'leri proxy ile saran altyapısıdır. Kendi annotation'ınız için bu altyapıyı sizin yazmanız gerekir: örneğin @Around("@annotation(audited)") pointcut'ı olan bir aspect ya da bir BeanPostProcessor. @Inherited yalnızca sınıf seviyesindeki annotation'ların alt sınıflara geçmesini sağlar ve davranış eklemez. Annotation tanımını @Component ile işaretlemek onu bir bean yapmaz ve bir anlam taşımaz. JVM, metot çağrısında annotation'ları otomatik değerlendirmez.$e$, 8),

-- 9. @Transactional --------------------------------------------------------

('spring-009',
$q$Bir sipariş servisinde ödeme başarısız olduğunda siparişin de kaydedilmemesi bekleniyor. Ancak PaymentException fırlatıldığında siparişin veritabanında kaldığı görülüyor. PaymentException, Exception sınıfından türeyen checked bir exception. Nedeni nedir?$q$,
$code$@Transactional
public void placeOrder(OrderRequest request) throws PaymentException {
    orderRepository.save(Order.from(request));
    paymentClient.charge(request);   // PaymentException fırlatabilir
}$code$,
$e$Spring'in varsayılan kuralına göre yalnızca RuntimeException ve Error rollback tetikler; checked exception'larda transaction commit edilir. Bu, EJB'den gelen bir gelenektir: checked exception'ın beklenen bir iş sonucu olduğu varsayılır. PaymentException checked olduğu için sipariş commit edilir. Çözüm @Transactional(rollbackFor = PaymentException.class) vermek ya da exception'ı unchecked yapmaktır. Ayrıca dış bir servis çağrısını uzun bir veritabanı transaction'ı içinde tutmamak gerekir: ağ beklemesi süresince bağlantı meşgul kalır ve iki sistemin atomik olarak birlikte commit edildiği izlenimi yanlıştır. İş akışı asenkron hale getirilebiliyorsa, yerel veritabanı değişikliği bir Outbox event'iyle birlikte kaydedilir ve servisler arası tutarlılık gerektiğinde Saga ile yönetilir; Outbox, senkron bir HTTP ödeme çağrısını tek başına atomik yapmaz. Spring Data repository metotları mevcut transaction'a katılır, ayrı commit yapmaz. Flush edilmiş değişiklikler de commit edilene kadar geri alınabilir.$e$, 9),

('spring-009b',
$q$Bir e-ticaret servisinde sadakat puanı eklenemese bile siparişin kaydedilmesi isteniyor. Bu yüzden puan ekleme çağrısı try/catch içine alınmış. LoyaltyService.addPoints da @Transactional ile işaretli (varsayılan propagation) ve bir RuntimeException fırlatıyor. placeOrder çalıştığında ne olur?$q$,
$code$@Service
public class OrderService {

    @Transactional
    public void placeOrder(Order order) {
        orderRepository.save(order);
        try {
            loyaltyService.addPoints(order);   // başka bir bean
        } catch (RuntimeException e) {
            log.warn("Puan eklenemedi, sipariş devam ediyor", e);
        }
    }
}$code$,
$e$addPoints varsayılan propagation olan REQUIRED ile çalışır, yani placeOrder'ın transaction'ına katılır. RuntimeException addPoints'in proxy'sinden geçerken Spring, katıldığı ortak transaction'ı rollback-only olarak işaretler. placeOrder exception'ı yakalasa da bu işaret kalkmaz; placeOrder bittiğinde Spring commit etmeye çalışır, transaction'ın rollback-only olduğunu görür, her şeyi geri alır ve UnexpectedRollbackException fırlatır. Sonuçta sipariş de kaydedilmez. Puan eklemenin siparişten bağımsız olması isteniyorsa addPoints REQUIRES_NEW ile ayrı bir transaction'da çalıştırılabilir (ek bir connection kullandığını unutmadan) ya da puan ekleme @TransactionalEventListener(phase = AFTER_COMMIT) ile commit sonrasına alınabilir. Başka bir bean'in @Transactional metodunu çağırmak geçerlidir; yok sayılmaz.$e$, 9),

-- 10. Bean scope'ları -------------------------------------------------------

('spring-010',
$q$Bir raporlama servisinde, her rapor için yeni bir ReportBuilder kullanılması amacıyla bu sınıf prototype olarak tanımlanmış. Ancak kullanıcılar, raporlarında önceki raporlara ait satırları da gördüklerini bildiriyor. Nedeni ve doğru çözüm hangisidir?$q$,
$code$@Component
@Scope("prototype")
public class ReportBuilder {
    private final List<String> lines = new ArrayList<>();
    public void add(String line) { lines.add(line); }
    public String render() { return String.join("\n", lines); }
}

@Service
public class ReportService {

    private final ReportBuilder builder;

    public ReportService(ReportBuilder builder) {
        this.builder = builder;
    }

    public String build(List<String> rows) {
        rows.forEach(builder::add);
        return builder.render();
    }
}$code$,
$e$Prototype scope, bean container'dan her istendiğinde yeni bir instance oluşturulması demektir. ReportService ise singleton'dır ve yalnızca bir kez oluşturulur; bu yüzden bağımlılıkları da yalnızca bir kez, oluşturulurken enjekte edilir. Sonuçta ReportService'in ömrü boyunca hep aynı ReportBuilder kullanılır ve satırlar birikir; eşzamanlı isteklerde ayrıca thread-safety sorunu da oluşur. Her çağrıda yeni bir nesne almak için ObjectProvider<ReportBuilder> enjekte edilip getObject() çağrılır; @Lookup metodu veya scoped proxy de aynı sorunu çözer. ReportService'i de prototype yapmak, onu kullanan singleton'larda aynı sorunu bir üst katmana taşır. Prototype scope HTTP isteğiyle ilgili değildir; @Scope, @Component sınıflarında da çalışır.$e$, 10),

('spring-010b',
$q$Bir fiyatlandırma servisinde, yük testinde bazı müşterilere başka müşterilerin indirim oranının uygulandığı görülüyor. Tek kullanıcıyla yapılan testlerde ise hesaplama her zaman doğru. Nedeni ve doğru çözüm hangisidir?$q$,
$code$@Service
public class PriceCalculator {

    private final DiscountPolicy discountPolicy;
    private BigDecimal discount;

    public PriceCalculator(DiscountPolicy discountPolicy) {
        this.discountPolicy = discountPolicy;
    }

    public BigDecimal calculate(Order order, Customer customer) {
        discount = discountPolicy.rateFor(customer);
        return order.total().multiply(BigDecimal.ONE.subtract(discount));
    }
}$code$,
$e$@Service bean'leri varsayılan olarak singleton'dır: tüm istekler, yani tüm thread'ler aynı PriceCalculator nesnesini paylaşır. discount bir alan olduğu için bir thread'in yazdığı oranı, hesaplamasını bitirmeden önce başka bir thread ezebilir; bu klasik bir race condition'dır. İstek bazlı bir değer bean'in alanında değil local değişkende tutulmalıdır; singleton bean'ler stateless tasarlanmalıdır. BigDecimal immutable'dır, sorun değerin kendisinde değil paylaşılan alandadır; AtomicReference ise okuma ve yazmanın arasındaki bileşik işlemi korumaz. Bean'i request scope yapmak sorunu gizler ama gereksiz bir proxy ve nesne maliyeti ekler; durum zaten local değişkene ait. Spring singleton'ın thread başına kopyasını oluşturmaz.$e$, 10),

-- 11. Stereotype annotation'lar ve @Bean ------------------------------------

('spring-011',
$q$Bir entegrasyon modülünde iki istemcinin aynı bağlantı havuzunu paylaşması amaçlanıyor. Ancak izleme ekranında üç ayrı ConnectionPool nesnesi oluştuğu ve istemcilerin farklı havuzlar kullandığı görülüyor. Nedeni nedir?$q$,
$code$@Configuration(proxyBeanMethods = false)
public class ClientConfig {

    @Bean
    public ConnectionPool connectionPool() {
        return new ConnectionPool(50);
    }

    @Bean
    public OrderClient orderClient() {
        return new OrderClient(connectionPool());
    }

    @Bean
    public StockClient stockClient() {
        return new StockClient(connectionPool());
    }
}$code$,
$e$@Configuration sınıfları varsayılan olarak (proxyBeanMethods = true) CGLIB ile proxy'lenir. Bu modda bir @Bean metodundan diğerini çağırmak proxy'den geçer ve container'daki singleton döner. proxyBeanMethods = false verildiğinde ise sınıf proxy'lenmez (lite mode): connectionPool() çağrısı sıradan bir Java metot çağrısıdır ve her seferinde new ConnectionPool çalışır. Böylece biri container'daki bean, ikisi istemcilerin içinde olmak üzere üç havuz oluşur. Lite mode'da doğru yol, bağımlılığı metot parametresi olarak almaktır: orderClient(ConnectionPool connectionPool). Aynı durum @Component sınıflarındaki @Bean metotları için de geçerlidir. @Bean metotlarının varsayılan scope'u singleton'dır ve Spring bu metotları paralel çağırmaz.$e$, 11),

('spring-011b',
$q$Bir kullanıcı servisinde, aynı e-postayla ikinci kayıt denendiğinde DataIntegrityViolationException yakalanıp kullanıcıya anlamlı bir mesaj dönülüyor. Spring Data repository kullanılırken bu kod çalışıyor; ancak sorgular için EntityManager'ı doğrudan kullanan elle yazılmış bir DAO'ya geçilince Hibernate'in ConstraintViolationException'ı yakalanmadan yukarı sızıyor. Nedeni nedir?$q$,
$code$@Component
public class JpaUserDao {

    @PersistenceContext
    private EntityManager em;

    public void insert(User user) {
        em.persist(user);
        em.flush();
    }
}$code$,
$e$@Component, @Service, @Repository ve @Controller'ın hepsi bileşeni component scan ile bean olarak kaydeder; ancak @Repository'nin ek bir davranışı vardır: exception translation. Bu, annotation'ın kendi başına yaptığı bir şey değildir; Spring'in persistence exception translation altyapısı aktif olduğunda (Spring Boot'ta JPA kurulumuyla birlikte hazır gelir), @Repository ile işaretli bean'ler PersistenceExceptionTranslationPostProcessor tarafından bir proxy ile sarılır ve JPA ya da Hibernate'e özgü exception'lar Spring'in DataAccessException hiyerarşisine (ör. DataIntegrityViolationException) çevrilir. Spring Data repository'leri bu davranışa zaten sahiptir. DAO @Component ile işaretlendiği için bu çeviri yapılmaz ve Hibernate'e özgü exception sızar. Çözüm, sınıfı @Repository ile işaretlemektir. Bu da servisin persistence teknolojisine özgü exception'lara bağımlı olmasını engeller. @Service teknik olarak @Component ile aynıdır ve bu çeviriyi yapmaz.$e$, 11),

-- 12. Injection türleri -----------------------------------------------------

('spring-012',
$q$Bir fatura servisinin unit testinde, servis new ile oluşturulup createInvoice çağrıldığında NullPointerException alınıyor. Ekip, servisi Spring context'i ayağa kaldırmadan, mock bağımlılıklarla test edebilmek istiyor. En doğru değişiklik hangisidir?$q$,
$code$@Service
public class InvoiceService {

    @Autowired
    private InvoiceRepository invoiceRepository;

    @Autowired
    private MailSender mailSender;

    public Invoice createInvoice(Order order) { ... }
}

// Test
InvoiceService service = new InvoiceService();
service.createInvoice(order);   // NullPointerException$code$,
$e$Field injection bağımlılıkları gizler: sınıfın dışından hangi bağımlılıklara ihtiyaç duyduğu görülmez, alanlar final olamaz ve nesne Spring olmadan oluşturulduğunda alanlar null kalır. Testte bu alanları doldurmak için reflection ya da Spring context gerekir. Constructor injection'da bağımlılıklar constructor parametreleri ve final alanlar olur; nesne her zaman eksiksiz oluşturulur ve test new InvoiceService(repositoryMock, mailSenderMock) ile kurulur. Sınıfın tek constructor'ı varsa Spring 4.3'ten beri @Autowired yazmak gerekmez. @SpringBootTest bir unit test için gereksiz ölçüde ağırdır ve asıl tasarım sorununu çözmez. Alanları public yapmak encapsulation'ı bozar ve alanlar yine final olamaz. Setter injection bağımlılıkları zorunlu kılmaz; nesne setter çağrılmadan da oluşturulabilir.$e$, 12),

('spring-012b',
$q$Spring Boot 3'e geçen bir projede OrderService ile CustomerService constructor injection ile birbirine bağımlı ve uygulama açılırken döngüsel bağımlılık hatası veriyor. Bir geliştirici iki çözüm öneriyor: birine @Lazy eklemek ya da spring.main.allow-circular-references=true ayarını açmak. En doğru değerlendirme hangisidir?$q$,
$code$@Service
public class OrderService {
    public OrderService(CustomerService customerService) { ... }
}

@Service
public class CustomerService {
    public CustomerService(OrderService orderService) { ... }
}$code$,
$e$İki bean'in birbirine doğrudan ve eager constructor bağımlılığı çözülemez: her biri oluşturulabilmek için diğerinin önceden oluşturulmuş olmasını ister, bu yüzden hata açılışta alınır. Bağımlılıklardan birinin constructor parametresine @Lazy eklemek, gerçek bean yerine bir lazy proxy enjekte ederek bu döngüyü teknik olarak kırar ve uygulama açılır; hedef bean daha sonra normal şekilde oluşturulabiliyorsa uygulama da çalışır. Ancak bu, iki sınıfın birbirinin sorumluluğuna karışmış olduğu mimari sorunu gizler ve kalıcı bir tasarım çözümü olarak tercih edilmez. spring.main.allow-circular-references=true ise Spring Boot 2.6 öncesi davranışa dönmek için bir geçiş ayarıdır; field ve setter injection'daki döngülere izin verir ama doğrudan constructor döngüsünü kendi başına çözmez. Spring Boot 2.6'dan beri döngüsel referanslar varsayılan olarak yasak olduğu için field injection'a geçmek de tek başına sorunu çözmez. Kalıcı çözüm sorumlulukları yeniden ayırmaktır: ortak ihtiyaç üçüncü bir bean'e taşınır ya da bağımlılıklardan biri ters çevrilir, örneğin CustomerService'in OrderService'i çağırması yerine bir event yayınlaması.$e$, 12);

CREATE TEMP TABLE spring_options (
    question_id varchar(50) NOT NULL REFERENCES spring_questions(id),
    text text NOT NULL,
    is_correct boolean NOT NULL,
    sort_order integer NOT NULL,
    PRIMARY KEY (question_id, sort_order)
) ON COMMIT DROP;

INSERT INTO spring_options VALUES

('spring-001', $o$Öneri yanlıştır; singleton'lar açılışta oluştuğu için konfigürasyon hatası deploy anında yakalanır. @Lazy hatayı müşteri isteğine erteler.$o$, true, 0),
('spring-001', $o$Öneri doğrudur; ApplicationContext bean'leri zaten ilk kullanımda oluşturur, açılıştaki hata Spring Boot'un ayrı bir konfigürasyon doğrulamasından gelir.$o$, false, 1),
('spring-001', $o$Sorun BeanFactory davranışıdır; ApplicationContext kullanılsaydı bean ilk istendiğinde oluşturulur ve uygulama bu hataya rağmen sorunsuz açılırdı.$o$, false, 2),
('spring-001', $o$@Lazy yerine bean prototype yapılmalıdır; prototype bean'ler açılışta oluşturulmadığı için uygulama ayağa kalkar ve her istekte yeniden denenir.$o$, false, 3),

('spring-001b', $o$BeanFactory annotation'ları okuyamaz; @Autowired ve @Transactional yalnızca ApplicationContext'in yüklediği sınıflarda runtime'da görünür.$o$, false, 0),
('spring-001b', $o$BeanFactory bean'leri lazy oluşturduğu için @Autowired ve @Transactional ancak bean'in ilk metot çağrısı tamamlandıktan sonra devreye girer.$o$, false, 1),
('spring-001b', $o$Bu davranışlar BeanPostProcessor'larla çalışır; annotation tabanlı context bunları kaydeder, çıplak BeanFactory'de elle eklenmeleri gerekir.$o$, true, 2),
('spring-001b', $o$Sorun component scan'in yapılmamasıdır; test sınıfına @ComponentScan eklenirse BeanFactory de bu annotation'ları kendiliğinden işler.$o$, false, 3),

('spring-002', $o$readOnly = true transaction açmaz, yalnızca bir ipucudur; bu parametre kaldırılırsa @PostConstruct içinde de transaction açılır.$o$, false, 0),
('spring-002', $o$@PostConstruct proxy oluşmadan ham nesnede çalışır, çağrı da this üzerindendir; iş TransactionTemplate'le ya da proxy üzerinden yapılmalı.$o$, true, 1),
('spring-002', $o$@PostConstruct metotlarını Spring değil JVM çağırır; bu yüzden Spring'in o metot içinden yapılan hiçbir çağrıya müdahale etme şansı yoktur.$o$, false, 2),
('spring-002', $o$@Transactional sınıf seviyesine taşınmalıdır; o zaman init içinden yapılan loadAll çağrısı da proxy'den geçer ve transaction açılır.$o$, false, 3),

('spring-002b', $o$Prototype bean'lerin @PreDestroy metodu, nesne garbage collector tarafından toplandığında çağrılır; GC gecikmesi dosyaların birikmesine yol açar.$o$, false, 0),
('spring-002b', $o$@PreDestroy yerine DisposableBean arayüzü uygulanmalıdır; Spring prototype bean'lerde yalnızca bu arayüzün destroy metodunu çağırır.$o$, false, 1),
('spring-002b', $o$Prototype bean'ler singleton bir bean'e enjekte edilseydi destroy callback'leri o singleton'ınkiyle birlikte çağrılırdı; sorun getObject kullanımıdır.$o$, false, 2),
('spring-002b', $o$Spring prototype bean'i teslim ettikten sonra takip etmez ve @PreDestroy'u hiç çağırmaz; kaynak, nesneyi kullanan kodda kapatılmalıdır.$o$, true, 3),

('spring-003', $o$Bir servisin OrderRepository'yi constructor parametresi olarak alması ve onu oluşturma işini tamamen container'a bırakması$o$, false, 0),
('spring-003', $o$Bir sınıfın ihtiyaç duyduğu repository'yi ServiceLocator.get(OrderRepository.class) çağrısıyla kendisinin bulması$o$, false, 1),
('spring-003', $o$JdbcTemplate'in bağlantı, hata ve kaynak yönetimini kendisi yapıp yalnızca satır eşleme callback'ini çağırması$o$, true, 2),
('spring-003', $o$Bir sınıfın bağımlılığını new ile oluşturup alanında tutması ve testte bu alanı bir alt sınıfla değiştirmesi$o$, false, 3),

('spring-003b', $o$AOP: bu konular aspect olarak bir kez tanımlanır, Spring bean'leri proxy ile sarar ve metot çağrılarının etrafına bu davranışı ekler.$o$, true, 0),
('spring-003b', $o$Spring MVC interceptor'ları: HandlerInterceptor, uygulamadaki tüm servis metodu çağrılarını yakalayıp öncesine ve sonrasına kod ekler.$o$, false, 1),
('spring-003b', $o$BeanFactoryPostProcessor: bean tanımlarını container başlarken değiştirir ve her servis metodunun başına gerekli kontrol kodunu ekler.$o$, false, 2),
('spring-003b', $o$ApplicationEvent: Spring her servis metodu çağrıldığında bir event yayınlar; loglama ve yetki kontrolü bu event'leri dinleyerek yapılır.$o$, false, 3),

('spring-004', $o$Spring Boot, Spring Framework'ün yerini alan ve kendi IoC container'ını, kendi transaction altyapısını getiren ayrı bir framework'tür.$o$, false, 0),
('spring-004', $o$Auto-configuration derleme zamanında kod üretir; bu sayede Spring Boot uygulamalarında runtime'da reflection kullanımı tamamen ortadan kalkar.$o$, false, 1),
('spring-004', $o$Embedded server kullanıldığı için Spring Boot uygulamaları harici bir Tomcat sunucusuna WAR olarak deploy edilemez, yalnızca java -jar ile çalışır.$o$, false, 2),
('spring-004', $o$Spring Boot, Framework'ün üzerine auto-configuration, starter'lar, embedded server ve dış konfigürasyon ekler; container yine Spring'indir.$o$, true, 3),

('spring-004b', $o$Her ortam için ayrı jar üretmek doğrudur; Spring Boot konfigürasyonu derleme zamanında okuduğu için değerler çalışma anında değiştirilemez.$o$, false, 0),
('spring-004b', $o$Tek bir artifact üretilmeli, ortam farkları profiller ve environment variable'larla verilmeli; bunlar jar içindeki application.yml'i ezer.$o$, true, 1),
('spring-004b', $o$application.yml'deki değer her zaman önceliklidir; environment variable'lar yalnızca yml dosyasında hiç bulunmayan anahtarlar için okunur.$o$, false, 2),
('spring-004b', $o$Değerler koda yazılmalı ve @Profile ile her ortam için ayrı DataSource bean'i tanımlanmalıdır; property dosyaları güvenli bir kaynak değildir.$o$, false, 3),

('spring-005', $o$Kendi DataSource bean'i varken auto-configuration @ConditionalOnMissingBean ile geri çekilir; hikari ayarları bu bean'e bağlanmaz.$o$, true, 0),
('spring-005', $o$Auto-configuration, kullanıcının tanımladığı DataSource'u kendi oluşturduğu bean ile değiştirir ve varsayılan 10'luk havuz ayarını uygular.$o$, false, 1),
('spring-005', $o$HikariCP havuz boyutunu yalnızca environment variable'dan okur; değer SPRING_DATASOURCE_HIKARI_MAXIMUM_POOL_SIZE olarak verilmelidir.$o$, false, 2),
('spring-005', $o$DataSourceAutoConfiguration spring.factories dosyasına eklenmediği için Spring Boot 3'te spring.datasource.* property'leri okunmaz.$o$, false, 3),

('spring-005b', $o$Spring Boot 3 auto-configuration sınıflarını component scan ile bulur; kütüphane sınıflarını uygulamanın ana paketinin altına taşımak yeterlidir.$o$, false, 0),
('spring-005b', $o$Boot 3'te @ConditionalOnClass kaldırıldığı için koşullu tanımlanan bean'ler oluşmaz; koşullar @Profile annotation'ı ile değiştirilmelidir.$o$, false, 1),
('spring-005b', $o$Boot 3 auto-configuration'ları yalnızca AutoConfiguration.imports dosyasından okur; sınıf oraya yazılıp @AutoConfiguration ile işaretlenmeli.$o$, true, 2),
('spring-005b', $o$spring.factories Boot 3'te hâlâ desteklenir; sorun javax'tan jakarta paketine geçiş nedeniyle sınıfın classpath'ten yüklenememesidir.$o$, false, 3),

('spring-006', $o$Template Method: @Cacheable metodun gövdesini sabit bir akışa yerleştirir; aynı sınıftan çağrıldığında akış iki kez çalışır ve önbellek sıfırlanır.$o$, false, 0),
('spring-006', $o$Proxy: önbellek mantığı bean'i saran proxy'dedir. Aynı sınıftan this ile yapılan çağrı proxy'yi atlar ve önbellek hiç kontrol edilmez.$o$, true, 1),
('spring-006', $o$Observer: @Cacheable metot çağrısını bir event olarak yayınlar; aynı sınıf içinden yapılan çağrılarda bu event'in listener'ı tetiklenmez.$o$, false, 2),
('spring-006', $o$Singleton: önbellek bean başına bir kez tutulur; aynı sınıftan çağrıldığında ikinci bir bean instance'ı oluştuğu için önbellek boş görünür.$o$, false, 3),

('spring-006b', $o$Yorum doğrudur; Spring singleton scope'u bir sınıftan tek instance olmasını garanti eder, bu yüzden uygulama açılışta hata vermelidir.$o$, false, 0),
('spring-006b', $o$Spring singleton scope'u thread başına bir instance oluşturur; bu yüzden iki bean tanımı da çalışma anında birden fazla nesneye dönüşür.$o$, false, 1),
('spring-006b', $o$@Bean metotlarıyla tanımlanan bean'ler varsayılan olarak prototype olduğu için aynı sınıftan iki nesne oluşması beklenen bir durumdur.$o$, false, 2),
('spring-006b', $o$Yorum yanlıştır; Spring singleton'ı bean tanımı ve container başına tek instance demektir. İki ayrı tanım, iki ayrı nesne üretir.$o$, true, 3),

('spring-007', $o$İkisi de HandlerInterceptor'da yapılmalıdır; interceptor Spring Security'den önce çalıştığı için reddedilen istekleri de görür ve metot bilgisine sahiptir.$o$, false, 0),
('spring-007', $o$Correlation id interceptor'da, süre ve metot loglama filter'da yapılmalıdır; filter hangi controller metodunun çalışacağını HandlerMapping'den öğrenir.$o$, false, 1),
('spring-007', $o$Correlation id, Security'den önce çalışan bir filter'da; controller metodu bazlı loglama ise handler'ı bilen bir HandlerInterceptor'da yapılmalıdır.$o$, true, 2),
('spring-007', $o$İkisi de @RestControllerAdvice ile yapılmalıdır; advice sınıfları tüm istekleri, statik dosyalar ve reddedilen istekler dahil yakalar.$o$, false, 3),

('spring-007b', $o$Gövde, controller'dan önceki argüman çözümleme adımında nesneye çevrilip doğrulanır; doğrulama başarısız olunca metot hiç çağrılmaz.$o$, true, 0),
('spring-007b', $o$Spring Security filter zinciri gövdedeki geçersiz alanları fark ederek isteği reddeder; doğrulama DispatcherServlet'ten önce yapılır.$o$, false, 1),
('spring-007b', $o$HandlerInterceptor.preHandle @Valid annotation'ını okuyup gövdeyi doğrular ve false döndürerek isteğin controller'a ulaşmasını engeller.$o$, false, 2),
('spring-007b', $o$Controller metodu çalışır ama dönüş değeri ViewResolver ile çözülemediği için 400 döner; log ise yanıt yazılamadığı için kaybolur.$o$, false, 3),

('spring-008', $o$@Transactional'ın retention'ı CLASS olduğu için annotation runtime'da okunamaz; bu yüzden yalnızca Spring'in derlediği sınıflarda etkilidir.$o$, false, 0),
('spring-008', $o$@Transactional yalnızca @Repository ile işaretli sınıflarda çalışır; ReportService @Service olduğu için annotation her durumda yok sayılır.$o$, false, 1),
('spring-008', $o$@Scheduled metotları transaction desteği olmayan ayrı bir thread havuzunda çalışır; Spring bu thread'lerde hiçbir transaction açamaz.$o$, false, 2),
('spring-008', $o$Annotation yalnızca metadata'dır; davranışı bean'i saran proxy sağlar. new ile oluşturulan nesne proxy'lenmediği için annotation etkisizdir.$o$, true, 3),

('spring-008b', $o$Annotation tanımına @Inherited eklenmelidir; bu olmadan annotation, Spring'in oluşturduğu proxy sınıfına aktarılmaz ve okunamaz.$o$, false, 0),
('spring-008b', $o$Annotation yalnızca metadata'dır; onu okuyup denetim kaydı yazacak bir aspect veya BeanPostProcessor yazılmadıkça hiçbir şey olmaz.$o$, true, 1),
('spring-008b', $o$Annotation tanımı @Component ile işaretlenmelidir; Spring yalnızca bean olarak kaydedilmiş annotation'ları metot çağrılarında işler.$o$, false, 2),
('spring-008b', $o$JVM, RUNTIME retention'lı annotation'ları metot çağrısında otomatik değerlendirir; sorun annotation'ın interface yerine sınıfta olmasıdır.$o$, false, 3),

('spring-009', $o$Varsayılan olarak yalnızca RuntimeException ve Error rollback tetikler; checked exception için rollbackFor ile kural tanımlanmalıdır.$o$, true, 0),
('spring-009', $o$save çağrısı hemen commit eder; Spring Data repository metotları her zaman kendi ayrı transaction'larını açtığı için dış transaction etkisizdir.$o$, false, 1),
('spring-009', $o$Rollback gerçekleşmiştir, ancak save'in INSERT'ü daha önce flush edildiği için geri alınamaz; flush edilen değişiklikler kalıcı hale gelir.$o$, false, 2),
('spring-009', $o$Proxy, metot imzasında throws ile bildirilen exception'ları göremez; rollback için exception metot içinde yakalanıp loglanmalıdır.$o$, false, 3),

('spring-009b', $o$Sipariş kaydedilir; exception yakalandığı için proxy hatayı görmez ve placeOrder'ın transaction'ı normal şekilde commit edilir.$o$, false, 0),
('spring-009b', $o$Sipariş kaydedilir ama puan eklenmez; addPoints REQUIRED olduğu için yalnızca kendi kısmı ayrı bir transaction olarak geri alınır.$o$, false, 1),
('spring-009b', $o$Ortak transaction rollback-only işaretlenir; placeOrder commit etmeye çalışınca UnexpectedRollbackException alınır, sipariş de kaydedilmez.$o$, true, 2),
('spring-009b', $o$addPoints'teki @Transactional yok sayılır, çünkü bir transaction içinden başka bir bean'in transactional metodu çağrılamaz; sipariş kaydedilir.$o$, false, 3),

('spring-010', $o$Prototype scope her HTTP isteği için yeni bir instance üretir; sorun ReportService'in prototype olmamasıdır, o da prototype yapılmalıdır.$o$, false, 0),
('spring-010', $o$Prototype, singleton'a yalnızca bir kez, oluşturulurken enjekte edilir; her raporda yeni nesne için ObjectProvider ile getObject() çağrılmalı.$o$, true, 1),
('spring-010', $o$@Scope("prototype") yalnızca @Bean metotlarında geçerlidir; @Component sınıflarında yok sayıldığı için ReportBuilder singleton olarak kalır.$o$, false, 2),
('spring-010', $o$lines alanı final olduğu için liste nesneler arasında paylaşılır; final kaldırılır ve her render çağrısında yeni bir liste atanırsa sorun çözülür.$o$, false, 3),

('spring-010b', $o$BigDecimal mutable olduğu için değer thread'ler arasında bozulur; alan AtomicReference<BigDecimal> yapılırsa her müşteri doğru oranı alır.$o$, false, 0),
('spring-010b', $o$Servis bean'leri durum tuttuğu için her zaman request scope olmalıdır; sınıfa @Scope("request") eklenmesi bu sorunu kalıcı olarak çözer.$o$, false, 1),
('spring-010b', $o$Spring her thread için singleton bean'in ayrı bir kopyasını oluşturur; sorun DiscountPolicy'nin tüm thread'ler arasında paylaşılmasıdır.$o$, false, 2),
('spring-010b', $o$Bean singleton'dır ve tüm thread'ler aynı nesneyi paylaşır; istek bazlı discount değeri alanda değil local değişkende tutulmalıdır.$o$, true, 3),

('spring-011', $o$@Bean metotlarının varsayılan scope'u prototype olduğu için connectionPool her çağrıldığında yeni bir nesne üretir; @Scope("singleton") eklenmeli.$o$, false, 0),
('spring-011', $o$@Configuration yerine @Component kullanılmalıdır; @Component sınıflarındaki @Bean metotlarının birbirini çağırması aynı singleton'ı döndürür.$o$, false, 1),
('spring-011', $o$proxyBeanMethods = false ile sınıf proxy'lenmez ve connectionPool() çağrısı sıradan bir metot çağrısı olur; havuz parametre olarak alınmalı.$o$, true, 2),
('spring-011', $o$Spring @Bean metotlarını açılışta paralel çağırdığı için havuz yarış durumunda birden fazla kez oluşur; metotlar synchronized yapılmalıdır.$o$, false, 3),

('spring-011b', $o$@Repository'nin exception translation davranışı vardır, @Component'in yoktur; DAO sınıfı @Repository ile işaretlenmelidir.$o$, true, 0),
('spring-011b', $o$@Component ile @Repository teknik olarak tamamen aynıdır; sorun servisin Hibernate'in ConstraintViolationException'ını yakalamamasıdır.$o$, false, 1),
('spring-011b', $o$DAO @Service ile işaretlenmelidir; Spring, iş katmanında fırlatılan veritabanı exception'larını DataAccessException hiyerarşisine çevirir.$o$, false, 2),
('spring-011b', $o$Exception translation yalnızca Spring Data interface'leri için çalışır; EntityManager'ı doğrudan kullanan DAO'larda bu mümkün değildir.$o$, false, 3),

('spring-012', $o$Test sınıfına @SpringBootTest eklenmelidir; field injection'ın tek sakıncası testte Spring context gerektirmesidir, tasarımın değişmesi gerekmez.$o$, false, 0),
('spring-012', $o$Alanlar public yapılmalı ve testte doğrudan atanmalıdır; böylece bağımlılıklar hem dışarıdan görünür hem de testte kolayca değiştirilebilir.$o$, false, 1),
('spring-012', $o$Setter injection'a geçilmelidir; setter'lar bağımlılıkları zorunlu kılar ve nesnenin bağımlılıkları eksik olarak oluşturulmasını engeller.$o$, false, 2),
('spring-012', $o$Constructor injection'a geçilmelidir; bağımlılıklar final alan olur, nesne hep eksiksiz oluşur ve testte mock'larla new ile kurulabilir.$o$, true, 3),

('spring-012b', $o$@Lazy eklemek en doğru çözümdür; döngü bir proxy ile ertelenir, çalışma zamanında hiçbir maliyet ya da risk oluşturmadan ortadan kalkar.$o$, false, 0),
('spring-012b', $o$Döngü bir tasarım kokusudur; ortak sorumluluk üçüncü bir bean'e taşınmalı veya bağımlılığın yönü örneğin bir event ile değiştirilmelidir.$o$, true, 1),
('spring-012b', $o$Field injection'a geçilmelidir; Spring Boot, field injection'daki döngüsel bağımlılıkları her sürümde varsayılan olarak otomatik çözer.$o$, false, 2),
('spring-012b', $o$allow-circular-references=true kalıcı çözümdür; ayar yalnızca eski projelerle uyumluluk için kapalı gelir, açılmasının bir sakıncası yoktur.$o$, false, 3);

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM questions q
        JOIN spring_questions s ON s.id = q.id
        WHERE q.quiz_id IS DISTINCT FROM (SELECT quiz_id FROM spring_target)
    ) THEN
        RAISE EXCEPTION 'A Spring question ID is already used by another quiz';
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
    WHERE q.quiz_id = (SELECT quiz_id FROM spring_target)
      AND q.id NOT IN (SELECT id FROM spring_questions);
    IF unknown_ids IS NOT NULL THEN
        RAISE EXCEPTION 'Spring quiz contains questions not managed by this seed: %', unknown_ids;
    END IF;
END;
$$;

INSERT INTO questions (id, quiz_id, type, text, image_url, code_snippet, explanation, score, sort_order)
SELECT s.id, t.quiz_id, 'mcq', s.text, '', s.code_snippet, s.explanation, 1, s.sort_order
FROM spring_questions s
CROSS JOIN spring_target t
ON CONFLICT (id) DO NOTHING;

-- Refresh wording for all seeded Spring questions.
UPDATE questions q
SET text = s.text,
    code_snippet = s.code_snippet,
    explanation = s.explanation,
    sort_order = s.sort_order
FROM spring_questions s
WHERE q.id = s.id
  AND q.quiz_id = (SELECT quiz_id FROM spring_target)
  AND (q.text, q.code_snippet, q.explanation, q.sort_order)
      IS DISTINCT FROM
      (s.text, s.code_snippet, s.explanation, s.sort_order);

INSERT INTO options (question_id, text, is_correct, match_text, sort_order)
SELECT s.question_id, s.text, s.is_correct, '', s.sort_order
FROM spring_options s
WHERE NOT EXISTS (
    SELECT 1 FROM options o WHERE o.question_id = s.question_id
);

-- Refresh option wording and correct-answer positions for every seeded Spring question.
UPDATE options o
SET text = s.text,
    is_correct = s.is_correct
FROM spring_options s
JOIN questions q ON q.id = s.question_id
WHERE o.question_id = s.question_id
  AND o.sort_order = s.sort_order
  AND q.quiz_id = (SELECT quiz_id FROM spring_target)
  AND (o.text, o.is_correct) IS DISTINCT FROM (s.text, s.is_correct);

DO $$
BEGIN
    IF (SELECT count(*) FROM questions WHERE quiz_id = (SELECT quiz_id FROM spring_target)) <> 24 THEN
        RAISE EXCEPTION 'Expected exactly twenty-four questions in the Spring quiz';
    END IF;

    IF EXISTS (
        SELECT q.id
        FROM questions q
        JOIN spring_questions s ON s.id = q.id
        LEFT JOIN options o ON o.question_id = q.id
        GROUP BY q.id
        HAVING count(o.id) <> 4
            OR count(o.id) FILTER (WHERE o.is_correct) <> 1
    ) THEN
        RAISE EXCEPTION 'Each seeded Spring question must have four options and one correct answer';
    END IF;
END;
$$;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM questions
        WHERE quiz_id = (SELECT quiz_id FROM spring_target)
        GROUP BY sort_order
        HAVING count(*) <> 2
    ) THEN
        RAISE EXCEPTION 'Each Spring topic (sort_order) must have exactly two variants';
    END IF;

    IF (SELECT array_agg(DISTINCT sort_order ORDER BY sort_order)
        FROM questions
        WHERE quiz_id = (SELECT quiz_id FROM spring_target)) IS DISTINCT FROM ARRAY[1,2,3,4,5,6,7,8,9,10,11,12] THEN
        RAISE EXCEPTION 'Expected Spring topic groups 1 to 12';
    END IF;
END;
$$;

COMMIT;
