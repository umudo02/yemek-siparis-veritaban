-- ============================================================
-- VTYS-1 DÖNEM PROJESİ
-- Çevrimiçi Yemek Sipariş Platformu Veritabanı
-- "Askıda Yemek" Modülü Dahil
-- SQL Server (T-SQL) uyumlu
-- ============================================================

-- Veritabanını oluştur
CREATE DATABASE YemekSiparisDB;
GO
USE YemekSiparisDB;
GO

-- ============================================================
-- 1. TABLOLAR (DDL & Constraints)
-- ============================================================

-- -----------------------------------------------
-- KULLANICILAR: Müşteriler, Kuryeler vb. ortak taban
-- -----------------------------------------------
CREATE TABLE Kullanicilar (
    KullaniciID     INT IDENTITY(1,1) PRIMARY KEY,
    Ad              NVARCHAR(50)  NOT NULL,
    Soyad           NVARCHAR(50)  NOT NULL,
    Email           NVARCHAR(100) NOT NULL UNIQUE,
    Telefon         NVARCHAR(15)  NOT NULL UNIQUE,
    Sifre           NVARCHAR(255) NOT NULL,
    Rol             NVARCHAR(20)  NOT NULL DEFAULT 'Musteri',  -- Musteri | Kurye | Admin
    IhtiyacSahibi   BIT           NOT NULL DEFAULT 0,  -- Askıda Yemek havuzunu kullanabilir mi?
    IsActive        BIT           NOT NULL DEFAULT 1,  -- Soft Delete
    KayitTarihi     DATETIME      NOT NULL DEFAULT GETDATE(),
    CONSTRAINT CHK_Rol CHECK (Rol IN ('Musteri','Kurye','Admin'))
);
GO

-- -----------------------------------------------
-- RESTORANLAR
-- -----------------------------------------------
CREATE TABLE Restoranlar (
    RestoranID      INT IDENTITY(1,1) PRIMARY KEY,
    RestoranAdi     NVARCHAR(100) NOT NULL,
    Adres           NVARCHAR(255) NOT NULL,
    Telefon         NVARCHAR(15)  NOT NULL UNIQUE,
    Email           NVARCHAR(100) NOT NULL UNIQUE,
    Puan            DECIMAL(3,2)  NOT NULL DEFAULT 0.00,
    ToplamCiro      DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    IsActive        BIT           NOT NULL DEFAULT 1,
    KayitTarihi     DATETIME      NOT NULL DEFAULT GETDATE(),
    CONSTRAINT CHK_Puan CHECK (Puan BETWEEN 0 AND 5)
);
GO

-- -----------------------------------------------
-- KATEGORİLER (Restoran'a özgü menü kategorileri)
-- -----------------------------------------------
CREATE TABLE Kategoriler (
    KategoriID      INT IDENTITY(1,1) PRIMARY KEY,
    RestoranID      INT           NOT NULL,
    KategoriAdi     NVARCHAR(50)  NOT NULL,
    IsActive        BIT           NOT NULL DEFAULT 1,
    CONSTRAINT FK_Kategori_Restoran FOREIGN KEY (RestoranID) REFERENCES Restoranlar(RestoranID)
);
GO

-- -----------------------------------------------
-- MENÜ ÜRÜNLERİ
-- -----------------------------------------------
CREATE TABLE MenuUrunleri (
    UrunID          INT IDENTITY(1,1) PRIMARY KEY,
    RestoranID      INT            NOT NULL,
    KategoriID      INT            NULL,
    UrunAdi         NVARCHAR(100)  NOT NULL,
    Aciklama        NVARCHAR(255)  NULL,
    Fiyat           DECIMAL(8,2)   NOT NULL,
    IsActive        BIT            NOT NULL DEFAULT 1,
    CONSTRAINT FK_Urun_Restoran  FOREIGN KEY (RestoranID)  REFERENCES Restoranlar(RestoranID),
    CONSTRAINT FK_Urun_Kategori  FOREIGN KEY (KategoriID)  REFERENCES Kategoriler(KategoriID),
    CONSTRAINT CHK_UrunFiyat    CHECK (Fiyat > 0)
);
GO

-- -----------------------------------------------
-- SİPARİŞLER (Ana başlık)
-- -----------------------------------------------
CREATE TABLE Siparisler (
    SiparisID       INT IDENTITY(1,1) PRIMARY KEY,
    KullaniciID     INT            NOT NULL,
    RestoranID      INT            NOT NULL,
    KuryeID         INT            NULL,
    Durum           NVARCHAR(30)   NOT NULL DEFAULT 'Beklemede',
    -- Beklemede | Onaylandi | Hazirlaniyor | YolaDikti | TeslimEdildi | Iptal
    ToplamTutar     DECIMAL(10,2)  NOT NULL,
    AskidaYemekMi   BIT            NOT NULL DEFAULT 0,  -- Askıda havuzundan mı karşılandı?
    OlusturmaTarihi DATETIME       NOT NULL DEFAULT GETDATE(),
    GuncellemeTarihi DATETIME      NULL,
    CONSTRAINT FK_Siparis_Kullanici FOREIGN KEY (KullaniciID) REFERENCES Kullanicilar(KullaniciID),
    CONSTRAINT FK_Siparis_Restoran  FOREIGN KEY (RestoranID)  REFERENCES Restoranlar(RestoranID),
    CONSTRAINT FK_Siparis_Kurye     FOREIGN KEY (KuryeID)     REFERENCES Kullanicilar(KullaniciID),
    CONSTRAINT CHK_SiparisTutar     CHECK (ToplamTutar >= 0),
    CONSTRAINT CHK_SiparisDurum     CHECK (Durum IN ('Beklemede','Onaylandi','Hazirlaniyor','YolaDikti','TeslimEdildi','Iptal'))
);
GO

-- -----------------------------------------------
-- SİPARİŞ DETAYLARI (Sepet kalemleri)
-- -----------------------------------------------
CREATE TABLE SiparisDetaylari (
    DetayID         INT IDENTITY(1,1) PRIMARY KEY,
    SiparisID       INT            NOT NULL,
    UrunID          INT            NOT NULL,
    Miktar          INT            NOT NULL DEFAULT 1,
    BirimFiyat      DECIMAL(8,2)   NOT NULL,
    CONSTRAINT FK_Detay_Siparis FOREIGN KEY (SiparisID) REFERENCES Siparisler(SiparisID),
    CONSTRAINT FK_Detay_Urun   FOREIGN KEY (UrunID)    REFERENCES MenuUrunleri(UrunID),
    CONSTRAINT CHK_Miktar      CHECK (Miktar > 0),
    CONSTRAINT CHK_BirimFiyat  CHECK (BirimFiyat > 0)
);
GO

-- -----------------------------------------------
-- DEĞERLENDİRMELER (Sipariş bazlı yorum/puan)
-- -----------------------------------------------
CREATE TABLE Degerlendirmeler (
    DegerlendirmeID INT IDENTITY(1,1) PRIMARY KEY,
    SiparisID       INT            NOT NULL UNIQUE,  -- Her siparişe 1 değerlendirme
    KullaniciID     INT            NOT NULL,
    RestoranID      INT            NOT NULL,
    Puan            TINYINT        NOT NULL,
    Yorum           NVARCHAR(500)  NULL,
    Tarih           DATETIME       NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_Degerlendirme_Siparis   FOREIGN KEY (SiparisID)    REFERENCES Siparisler(SiparisID),
    CONSTRAINT FK_Degerlendirme_Kullanici FOREIGN KEY (KullaniciID)  REFERENCES Kullanicilar(KullaniciID),
    CONSTRAINT FK_Degerlendirme_Restoran  FOREIGN KEY (RestoranID)   REFERENCES Restoranlar(RestoranID),
    CONSTRAINT CHK_DegerPuan CHECK (Puan BETWEEN 1 AND 5)
);
GO

-- -----------------------------------------------
-- ASKIDA YEMEK BAĞIŞLARI
-- -----------------------------------------------
CREATE TABLE AskidaYemekBagislari (
    BagisID         INT IDENTITY(1,1) PRIMARY KEY,
    BagisciKullaniciID INT         NULL,   -- NULL = anonim bağış
    RestoranID      INT            NOT NULL,
    BagisYontemi    NVARCHAR(20)   NOT NULL DEFAULT 'Bakiye',  -- Bakiye | Urun
    BakiyeMiktar    DECIMAL(10,2)  NULL,   -- Bakiye bağışı ise
    UrunID          INT            NULL,   -- Ürün bağışı ise
    UrunAdedi       INT            NULL,
    Aciklama        NVARCHAR(255)  NULL,
    BagisTarihi     DATETIME       NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_Bagis_Bagisci  FOREIGN KEY (BagisciKullaniciID) REFERENCES Kullanicilar(KullaniciID),
    CONSTRAINT FK_Bagis_Restoran FOREIGN KEY (RestoranID)          REFERENCES Restoranlar(RestoranID),
    CONSTRAINT FK_Bagis_Urun     FOREIGN KEY (UrunID)              REFERENCES MenuUrunleri(UrunID),
    CONSTRAINT CHK_BagisYontemi  CHECK (BagisYontemi IN ('Bakiye','Urun')),
    CONSTRAINT CHK_BakiyeMiktar  CHECK (BakiyeMiktar IS NULL OR BakiyeMiktar > 0),
    CONSTRAINT CHK_UrunAdedi     CHECK (UrunAdedi IS NULL OR UrunAdedi > 0)
);
GO

-- -----------------------------------------------
-- ASKIDA YEMEK HAVUZU (Restoran başına kalan bakiye)
-- -----------------------------------------------
CREATE TABLE AskidaYemekHavuzu (
    HavuzID         INT IDENTITY(1,1) PRIMARY KEY,
    RestoranID      INT            NOT NULL UNIQUE,
    MevcutBakiye    DECIMAL(10,2)  NOT NULL DEFAULT 0.00,
    ToplamBagis     DECIMAL(10,2)  NOT NULL DEFAULT 0.00,
    ToplamKullanim  DECIMAL(10,2)  NOT NULL DEFAULT 0.00,
    SonGuncelleme   DATETIME       NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_Havuz_Restoran FOREIGN KEY (RestoranID) REFERENCES Restoranlar(RestoranID),
    CONSTRAINT CHK_HavuzBakiye   CHECK (MevcutBakiye >= 0)
);
GO

-- -----------------------------------------------
-- ASKIDA YEMEK KULLANIM LOG
-- -----------------------------------------------
CREATE TABLE AskidaYemekKullanim (
    KullanimID      INT IDENTITY(1,1) PRIMARY KEY,
    SiparisID       INT            NOT NULL,
    KullaniciID     INT            NOT NULL,
    RestoranID      INT            NOT NULL,
    KullanilanBakiye DECIMAL(10,2) NOT NULL,
    KullanimTarihi  DATETIME       NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_Kullanim_Siparis   FOREIGN KEY (SiparisID)   REFERENCES Siparisler(SiparisID),
    CONSTRAINT FK_Kullanim_Kullanici FOREIGN KEY (KullaniciID) REFERENCES Kullanicilar(KullaniciID),
    CONSTRAINT FK_Kullanim_Restoran  FOREIGN KEY (RestoranID)  REFERENCES Restoranlar(RestoranID),
    CONSTRAINT CHK_KullanilanBakiye  CHECK (KullanilanBakiye > 0)
);
GO


-- ============================================================
-- 2. İNDEKSLER (Performans)
-- ============================================================

-- Siparişlerde durum + tarih bazlı sorgular çok sık
CREATE INDEX IX_Siparisler_Durum_Tarih
    ON Siparisler (Durum, OlusturmaTarihi DESC);
GO

-- Menü arama; restoran + aktiflik
CREATE INDEX IX_MenuUrunleri_Restoran_Aktif
    ON MenuUrunleri (RestoranID, IsActive);
GO

-- Bağış sorgularında restoran filtresi
CREATE INDEX IX_AskidaBagis_Restoran_Tarih
    ON AskidaYemekBagislari (RestoranID, BagisTarihi DESC);
GO

-- Kullanıcı e-posta araması (login)
CREATE INDEX IX_Kullanicilar_Email
    ON Kullanicilar (Email);
GO
 
 
-- ============================================================
-- 3. MOCK VERİ (DML)
-- ============================================================
 
-- --- KULLANICILAR ---
INSERT INTO Kullanicilar (Ad, Soyad, Email, Telefon, Sifre, Rol, IhtiyacSahibi) VALUES
('Ahmet',    'Yılmaz',   'ahmet.yilmaz@mail.com',   '05321001001', 'hash_pw1',  'Musteri', 0),
('Fatma',    'Kaya',     'fatma.kaya@mail.com',     '05321001002', 'hash_pw2',  'Musteri', 0),
('Mehmet',   'Demir',    'mehmet.demir@mail.com',   '05321001003', 'hash_pw3',  'Musteri', 0),
('Ayşe',     'Çelik',    'ayse.celik@mail.com',     '05321001004', 'hash_pw4',  'Musteri', 0),
('Mustafa',  'Şahin',    'mustafa.sahin@mail.com',  '05321001005', 'hash_pw5',  'Musteri', 0),
('Zeynep',   'Arslan',   'zeynep.arslan@mail.com',  '05321001006', 'hash_pw6',  'Musteri', 0),
('Ali',      'Koç',      'ali.koc@mail.com',        '05321001007', 'hash_pw7',  'Musteri', 0),
('Hatice',   'Kurt',     'hatice.kurt@mail.com',    '05321001008', 'hash_pw8',  'Musteri', 0),
('İbrahim',  'Özdemir',  'ibrahim.ozdemir@mail.com','05321001009', 'hash_pw9',  'Musteri', 0),
('Elif',     'Doğan',    'elif.dogan@mail.com',     '05321001010', 'hash_pw10', 'Musteri', 0),
('Hüseyin',  'Yıldız',   'huseyin.yildiz@mail.com', '05321001011', 'hash_pw11', 'Musteri', 0),
('Merve',    'Aydın',    'merve.aydin@mail.com',    '05321001012', 'hash_pw12', 'Musteri', 0),
('Ömer',     'Erdoğan',  'omer.erdogan@mail.com',   '05321001013', 'hash_pw13', 'Musteri', 0),
('Selin',    'Çetin',    'selin.cetin@mail.com',    '05321001014', 'hash_pw14', 'Musteri', 0),
('Kadir',    'Aslan',    'kadir.aslan@mail.com',    '05321001015', 'hash_pw15', 'Musteri', 0),
('Büşra',    'Kılıç',    'busra.kilic@mail.com',    '05321001016', 'hash_pw16', 'Musteri', 0),
('Serhat',   'Aktaş',    'serhat.aktas@mail.com',   '05321001017', 'hash_pw17', 'Musteri', 0),
('Deniz',    'Güneş',    'deniz.gunes@mail.com',    '05321001018', 'hash_pw18', 'Musteri', 0),
-- İhtiyaç sahibi kullanıcılar (Askıda Yemek alabilirler)
('Ramazan',  'Tekin',    'ramazan.tekin@mail.com',  '05321001019', 'hash_pw19', 'Musteri', 1),
('Güler',    'Polat',    'guler.polat@mail.com',    '05321001020', 'hash_pw20', 'Musteri', 1),
-- Kuryeler
('Can',      'Demirci',  'can.demirci@mail.com',    '05321002001', 'hash_pw21', 'Kurye', 0),
('Enes',     'Taş',      'enes.tas@mail.com',       '05321002002', 'hash_pw22', 'Kurye', 0),
('Barış',    'Güler',    'baris.guler@mail.com',    '05321002003', 'hash_pw23', 'Kurye', 0);
GO
 
-- --- RESTORANLAR ---
INSERT INTO Restoranlar (RestoranAdi, Adres, Telefon, Email, Puan) VALUES
('Lezzet Durağı',        'Cumhuriyet Cad. No:5, Kadıköy',         '02161001001', 'info@lezzetdurag.com',   4.50),
('Kebap Sarayı',         'İstiklal Cad. No:12, Beyoğlu',          '02121001002', 'info@kebapsarayi.com',   4.20),
('Pizza World',          'Bağdat Cad. No:88, Maltepe',            '02161001003', 'info@pizzaworld.com',    3.90),
('Deniz Sofrası',        'Sahil Yolu No:34, Beşiktaş',            '02121001004', 'info@denizsofrasi.com',  4.70),
('Vegan Mutfak',         'Moda Cad. No:21, Kadıköy',              '02161001005', 'info@veganmutfak.com',   4.10),
('Burger Station',       'Taksim Meydanı No:3, Beyoğlu',          '02121001006', 'info@burgerstation.com', 3.80),
('Çin Lokantası',        'Nişantaşı, Abdi İpekçi Cad. No:7',     '02122001007', 'info@cinlokanta.com',    4.00);
GO
 
-- --- HAVUZ KAYITLARI (Her restoran için başlangıç) ---
INSERT INTO AskidaYemekHavuzu (RestoranID, MevcutBakiye, ToplamBagis, ToplamKullanim) VALUES
(1, 0, 0, 0),
(2, 0, 0, 0),
(3, 0, 0, 0),
(4, 0, 0, 0),
(5, 0, 0, 0),
(6, 0, 0, 0),
(7, 0, 0, 0);
GO
 
-- --- KATEGORİLER ---
INSERT INTO Kategoriler (RestoranID, KategoriAdi) VALUES
(1, 'Çorbalar'), (1, 'Ana Yemekler'), (1, 'Tatlılar'),
(2, 'Kebaplar'), (2, 'Mezeler'), (2, 'İçecekler'),
(3, 'Pizzalar'), (3, 'Makarnalar'), (3, 'Salatalar'),
(4, 'Balık'), (4, 'Deniz Ürünleri'), (4, 'Mezeler'),
(5, 'Vegan Ana'), (5, 'Vegan Atıştırmalık'),
(6, 'Burgerler'), (6, 'Patates & Ekstralar'),
(7, 'Çin Yemekleri'), (7, 'Sushi');
GO
 
-- --- MENÜ ÜRÜNLERİ (50+ ürün) ---
INSERT INTO MenuUrunleri (RestoranID, KategoriID, UrunAdi, Aciklama, Fiyat) VALUES
-- Lezzet Durağı (RestoranID=1)
(1, 1, 'Mercimek Çorbası',   'Klasik kırmızı mercimek',        45.00),
(1, 1, 'Domates Çorbası',    'Taze domatesli',                 40.00),
(1, 2, 'Kuru Fasulye',       'Pilav ile',                      95.00),
(1, 2, 'Tavuk Sote',         'Sebzeli',                        130.00),
(1, 2, 'Izgara Köfte',       'Yanında patates kızartması',     150.00),
(1, 3, 'Sütlaç',             'Fırında',                        55.00),
(1, 3, 'Baklava',            'Antep fıstıklı',                 80.00),
-- Kebap Sarayı (RestoranID=2)
(2, 4, 'Adana Kebap',        'Acılı kıyma kebap',              180.00),
(2, 4, 'Urfa Kebap',         'Sade kıyma kebap',               175.00),
(2, 4, 'Patlıcan Kebap',     'Patlıcanlı şiş',                 190.00),
(2, 4, 'Tavuk Kanat',        'Izgara kanat',                   160.00),
(2, 5, 'Haydari',            'Yoğurtlu meze',                   50.00),
(2, 5, 'Cacık',              'Salatalıklı yoğurt',              45.00),
(2, 6, 'Ayran',              '300ml',                           25.00),
(2, 6, 'Şalgam',             '300ml',                           20.00),
-- Pizza World (RestoranID=3)
(3, 7, 'Margarita Pizza',    'Domates, mozzarella',            140.00),
(3, 7, 'Karışık Pizza',      'Et, mantar, biber',              175.00),
(3, 7, 'Vejetaryen Pizza',   'Sebzeli',                        155.00),
(3, 7, 'Sucuklu Pizza',      'Türk sucuğu',                    165.00),
(3, 8, 'Bolonez Makarna',    'Kıymalı',                        145.00),
(3, 8, 'Carbonara',          'Kremalı',                        150.00),
(3, 9, 'Sezar Salata',       'Tavuklu',                        110.00),
-- Deniz Sofrası (RestoranID=4)
(4, 10,'Levrek Izgara',      'Taze levrek',                    280.00),
(4, 10,'Çipura Izgara',      'Taze çipura',                    270.00),
(4, 10,'Hamsi Tava',         'Mısır unlu hamsi',               200.00),
(4, 11,'Karides Güveç',      'Biberli karides',                250.00),
(4, 11,'Ahtapot Izgara',     'Zeytinyağlı',                    290.00),
(4, 12,'Deniz Börülcesi',    'Zeytinyağlı',                     80.00),
(4, 12,'Tarama',             'Balık yumurtası',                 75.00),
-- Vegan Mutfak (RestoranID=5)
(5, 13,'Nohutlu Buddha Bowl','Tahini soslu',                   160.00),
(5, 13,'Mercimekli Köfte',   'Vegan köfte',                    140.00),
(5, 13,'Falafel Tabağı',     'Hummuslu',                       150.00),
(5, 14,'Chia Puding',        'Badem sütlü',                     75.00),
(5, 14,'Meyve Salatası',     'Mevsim meyveleri',                65.00),
-- Burger Station (RestoranID=6)
(6, 15,'Classic Burger',     'Dana eti, cheddar',              170.00),
(6, 15,'Crispy Chicken Burger','Çıtır tavuk',                  165.00),
(6, 15,'BBQ Bacon Burger',   'Pastırmalı',                     185.00),
(6, 15,'Vegan Burger',       'Bitkisel pide',                  160.00),
(6, 16,'Patates Kızartması', 'Normal porsiyon',                 60.00),
(6, 16,'Soğan Halkası',      'Çıtır',                          65.00),
(6, 16,'Milkshake',          'Çikolata/Çilek/Vanilyalı',       80.00),
-- Çin Lokantası (RestoranID=7)
(7, 17,'Kung Pao Tavuk',     'Fıstıklı acılı',                 175.00),
(7, 17,'Chow Mein',          'Tavuklu noodle',                 160.00),
(7, 17,'Pekin Ördeği',       'Klasik Çin yemeği',              250.00),
(7, 17,'Spring Roll',        '4 adet',                          90.00),
(7, 18,'Sake Sushi (8 adet)','Somonlu',                        200.00),
(7, 18,'Tuna Maki (8 adet)', 'Ton balıklı',                    190.00),
(7, 18,'Veggie Roll (8 adet)','Sebzeli',                       160.00),
-- Pasife çekilmiş ürün örneği (Soft Delete)
(1, 2, 'Eski Pilav',         'Artık satışta değil',             50.00);
GO
 
-- Soft Delete: Eski pilav pasife çekildi
UPDATE MenuUrunleri SET IsActive = 0 WHERE UrunAdi = 'Eski Pilav';
GO
 
-- --- ASKIDA YEMEK BAĞIŞLARI ---
-- Bazı müşteriler bağış yapıyor (bazıları anonim)
INSERT INTO AskidaYemekBagislari (BagisciKullaniciID, RestoranID, BagisYontemi, BakiyeMiktar, Aciklama) VALUES
(1,  1, 'Bakiye', 200.00, 'Hayırlı olsun'),
(2,  1, 'Bakiye', 150.00, NULL),               -- Anonim değil ama açıklama yok
(NULL, 1,'Bakiye', 100.00, 'Anonim bağış'),   -- Gerçek anonim
(3,  2, 'Bakiye', 300.00, 'Ramazan bereketi'),
(4,  2, 'Bakiye', 200.00, NULL),
(5,  3, 'Bakiye', 250.00, 'İyi dilekler'),
(6,  4, 'Bakiye', 400.00, NULL),
(7,  5, 'Bakiye', 180.00, 'Herkese yetsin'),
(NULL, 6,'Bakiye', 300.00, 'Anonim hayırsever'),
(8,  1, 'Bakiye', 120.00, NULL);
GO
 
-- Havuzu güncelle (bağışları yansıt)
UPDATE AskidaYemekHavuzu SET MevcutBakiye = 570.00, ToplamBagis = 570.00 WHERE RestoranID = 1;
UPDATE AskidaYemekHavuzu SET MevcutBakiye = 500.00, ToplamBagis = 500.00 WHERE RestoranID = 2;
UPDATE AskidaYemekHavuzu SET MevcutBakiye = 250.00, ToplamBagis = 250.00 WHERE RestoranID = 3;
UPDATE AskidaYemekHavuzu SET MevcutBakiye = 400.00, ToplamBagis = 400.00 WHERE RestoranID = 4;
UPDATE AskidaYemekHavuzu SET MevcutBakiye = 180.00, ToplamBagis = 180.00 WHERE RestoranID = 5;
UPDATE AskidaYemekHavuzu SET MevcutBakiye = 300.00, ToplamBagis = 300.00 WHERE RestoranID = 6;
GO
 
-- --- SİPARİŞLER (100 adet) ---
-- Teslim edilmiş siparişler (normal)
DECLARE @i INT = 1;
WHILE @i <= 80
BEGIN
    DECLARE @uid INT   = (@i % 18) + 1;
    DECLARE @rid INT   = (@i % 6)  + 1;
    DECLARE @kid INT   = ((@i % 3)  + 21);  -- Kurye ID: 21,22,23
    DECLARE @tutar DECIMAL(10,2) = CAST((RAND(CHECKSUM(NEWID())) * 400 + 80) AS DECIMAL(10,2));
    INSERT INTO Siparisler (KullaniciID, RestoranID, KuryeID, Durum, ToplamTutar, AskidaYemekMi, OlusturmaTarihi)
    VALUES (@uid, @rid, @kid, 'TeslimEdildi', @tutar, 0, DATEADD(DAY, -@i, GETDATE()));
    SET @i = @i + 1;
END;
GO
 
-- Aktif/bekleyen siparişler
INSERT INTO Siparisler (KullaniciID, RestoranID, KuryeID, Durum, ToplamTutar, AskidaYemekMi) VALUES
(1,  1, 21, 'Hazirlaniyor', 190.00, 0),
(3,  2, 22, 'Onaylandi',    350.00, 0),
(5,  3, NULL,'Beklemede',   165.00, 0),
(7,  4, 23, 'YolaDikti',    280.00, 0),
(9,  5, 21, 'Hazirlaniyor', 310.00, 0),
(11, 6, 22, 'Onaylandi',    245.00, 0),
(13, 1, 23, 'Beklemede',    175.00, 0),
(15, 2, NULL,'Beklemede',   520.00, 0),
(17, 3, 21, 'YolaDikti',    155.00, 0),
-- Askıda Yemek ile verilen siparişler (ihtiyaç sahipleri)
(19, 1, 22, 'TeslimEdildi', 95.00,  1),  -- Ramazan (KullaniciID=19)
(20, 2, 23, 'TeslimEdildi', 175.00, 1);  -- Güler   (KullaniciID=20)
GO
 
-- SİPARİŞ DETAYLARI (bazı siparişler için)
INSERT INTO SiparisDetaylari (SiparisID, UrunID, Miktar, BirimFiyat) VALUES
(81,  3, 1, 95.00),  (81, 5, 1, 150.00),
(82,  8, 1, 180.00), (82, 12,1,  50.00),(82, 14,2, 25.00),
(83, 16, 1, 140.00), (83, 22,1, 110.00),
(84, 23, 1, 280.00),
(85, 30, 1, 160.00), (85, 31,1, 140.00),
(86, 35, 1, 170.00), (86, 40,1,  60.00),(86, 41,1, 65.00),
(87,  3, 2, 95.00),
(88,  8, 1, 180.00), (88,  9,1, 175.00),(88, 10,1, 190.00),
(89, 18, 1, 165.00),
-- Askıda siparişlerin detayları
(90,  1, 1, 45.00),  (90,  3,1, 95.00),   -- Ramazan: çorba + kuru fasulye
(91,  8, 1, 175.00);                        -- Güler: Urfa kebap
GO
 
-- ASKIDA KULLANIM LOG
INSERT INTO AskidaYemekKullanim (SiparisID, KullaniciID, RestoranID, KullanilanBakiye) VALUES
(90, 19, 1, 140.00),
(91, 20, 2, 175.00);
GO
 
-- Havuzu kullanım sonrası güncelle
UPDATE AskidaYemekHavuzu
SET MevcutBakiye = MevcutBakiye - 140.00, ToplamKullanim = ToplamKullanim + 140.00
WHERE RestoranID = 1;
 
UPDATE AskidaYemekHavuzu
SET MevcutBakiye = MevcutBakiye - 175.00, ToplamKullanim = ToplamKullanim + 175.00
WHERE RestoranID = 2;
GO
 
-- DEĞERLENDİRMELER
INSERT INTO Degerlendirmeler (SiparisID, KullaniciID, RestoranID, Puan, Yorum) VALUES
(1,  1,  1, 5, 'Harika lezzet, hızlı teslimat!'),
(2,  2,  2, 4, 'Kebaplar çok güzeldi.'),
(3,  3,  3, 3, 'Pizza biraz soğuk geldi.'),
(4,  4,  4, 5, 'Balık tazeliği mükemmeldi.'),
(5,  5,  5, 4, 'Vegan seçenekler çeşitli.'),
(6,  6,  6, 4, 'Burger lezzetliydi.'),
(7,  7,  1, 5, 'Her zaman tercihim.'),
(8,  8,  2, 5, 'Adana kebap muhteşem!'),
(9,  9,  3, 3, 'Beklediğimden farklıydı.'),
(10,10,  4, 5, 'Deniz ürünleri tazeydi.');
GO
 
 
-- ============================================================
-- 4. TETİKLEYİCİLER (Triggers)
-- ============================================================
 
-- -----------------------------------------------
-- Trigger 1: Sipariş "TeslimEdildi" statüsüne geçince
--            restoranın ToplamCiro'sunu güncelle
-- -----------------------------------------------
CREATE OR ALTER TRIGGER trg_SiparisTeslimEdildi
ON Siparisler
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    -- Sadece Durum 'TeslimEdildi' olarak değiştirilen satırlar
    IF EXISTS (
        SELECT 1 FROM inserted i
        JOIN deleted d ON i.SiparisID = d.SiparisID
        WHERE i.Durum = 'TeslimEdildi'
          AND d.Durum <> 'TeslimEdildi'
    )
    BEGIN
        UPDATE r
        SET r.ToplamCiro = r.ToplamCiro + i.ToplamTutar,
            r.Puan = (
                SELECT AVG(CAST(dg.Puan AS DECIMAL(3,2)))
                FROM Degerlendirmeler dg
                WHERE dg.RestoranID = r.RestoranID
            )
        FROM Restoranlar r
        JOIN inserted i ON r.RestoranID = i.RestoranID
        JOIN deleted  d ON i.SiparisID  = d.SiparisID
        WHERE i.Durum = 'TeslimEdildi'
          AND d.Durum <> 'TeslimEdildi'
          AND i.AskidaYemekMi = 0; -- Askıda siparişler ciroya sayılmaz
    END
END;
GO
 
-- -----------------------------------------------
-- Trigger 2: Askıda Yemek kullanımı (AskidaYemekKullanim
--            tablosuna INSERT) → Havuz bakiyesini düş
-- -----------------------------------------------
CREATE OR ALTER TRIGGER trg_AskidaKullanimBakiyeDus
ON AskidaYemekKullanim
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    -- Havuzda yeterli bakiye var mı kontrol et
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN AskidaYemekHavuzu h ON i.RestoranID = h.RestoranID
        WHERE h.MevcutBakiye < i.KullanilanBakiye
    )
    BEGIN
        RAISERROR('Askıda Yemek havuzunda yeterli bakiye yok!', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
 
    UPDATE h
    SET h.MevcutBakiye   = h.MevcutBakiye   - i.KullanilanBakiye,
        h.ToplamKullanim = h.ToplamKullanim  + i.KullanilanBakiye,
        h.SonGuncelleme  = GETDATE()
    FROM AskidaYemekHavuzu h
    JOIN inserted i ON h.RestoranID = i.RestoranID;
END;
GO
 
-- -----------------------------------------------
-- Trigger 3: Askıda Yemek bağışı (INSERT) →
--            Havuz bakiyesini artır
-- -----------------------------------------------
CREATE OR ALTER TRIGGER trg_AskidaBagisHavuzGuncelle
ON AskidaYemekBagislari
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE h
    SET h.MevcutBakiye  = h.MevcutBakiye  + ISNULL(i.BakiyeMiktar, 0),
        h.ToplamBagis   = h.ToplamBagis   + ISNULL(i.BakiyeMiktar, 0),
        h.SonGuncelleme = GETDATE()
    FROM AskidaYemekHavuzu h
    JOIN inserted i ON h.RestoranID = i.RestoranID
    WHERE i.BagisYontemi = 'Bakiye';
END;
GO
 
 
-- ============================================================
-- 5. GÖRÜNÜMLER (Views)
-- ============================================================
 
-- -----------------------------------------------
-- View 1: Aktif restoranların aktif menü ürünleri
-- -----------------------------------------------
CREATE OR ALTER VIEW vw_AktifRestoranMenuleri AS
SELECT
    r.RestoranID,
    r.RestoranAdi,
    r.Puan           AS RestoranPuani,
    k.KategoriAdi,
    u.UrunID,
    u.UrunAdi,
    u.Aciklama,
    u.Fiyat
FROM Restoranlar r
JOIN MenuUrunleri u  ON r.RestoranID  = u.RestoranID  AND u.IsActive = 1
LEFT JOIN Kategoriler k ON u.KategoriID = k.KategoriID AND k.IsActive = 1
WHERE r.IsActive = 1;
GO
 
-- -----------------------------------------------
-- View 2: Askıda Yemek havuz durumu özeti
-- -----------------------------------------------
CREATE OR ALTER VIEW vw_AskidaYemekHavuzDurumu AS
SELECT
    r.RestoranID,
    r.RestoranAdi,
    h.MevcutBakiye,
    h.ToplamBagis,
    h.ToplamKullanim,
    (SELECT COUNT(*) FROM AskidaYemekBagislari b WHERE b.RestoranID = r.RestoranID) AS ToplamBagisSayisi,
    (SELECT COUNT(*) FROM AskidaYemekKullanim  kul WHERE kul.RestoranID = r.RestoranID) AS ToplamKullanimSayisi,
    h.SonGuncelleme
FROM AskidaYemekHavuzu h
JOIN Restoranlar r ON h.RestoranID = r.RestoranID;
GO
 
-- -----------------------------------------------
-- View 3: Teslim edilmiş siparişlerin müşteri bazlı özeti
-- -----------------------------------------------
CREATE OR ALTER VIEW vw_MusteriSiparisDurumu AS
SELECT
    k.KullaniciID,
    k.Ad + ' ' + k.Soyad AS MusteriAdi,
    k.Email,
    COUNT(s.SiparisID)           AS ToplamSiparis,
    SUM(s.ToplamTutar)           AS ToplamHarcama,
    AVG(s.ToplamTutar)           AS OrtalamaSebet,
    MAX(s.OlusturmaTarihi)       AS SonSiparisTarihi
FROM Kullanicilar k
LEFT JOIN Siparisler s ON k.KullaniciID = s.KullaniciID AND s.Durum = 'TeslimEdildi'
WHERE k.Rol = 'Musteri' AND k.IsActive = 1
GROUP BY k.KullaniciID, k.Ad, k.Soyad, k.Email;
GO