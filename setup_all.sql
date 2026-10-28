-- setup_all.sql = database.sql + advanced.sql. Chạy lại bao nhiêu lần cũng KHÔNG mất dữ liệu đã nhập.
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;  -- trùng collation của bảng, tránh lỗi "Illegal mix of collations" trong view

-- KHÔNG xóa database: chạy lại file này nhiều lần dữ liệu vẫn giữ nguyên.
-- Muốn xóa sạch về dữ liệu mẫu ban đầu thì chạy reset_database.sql.
CREATE DATABASE IF NOT EXISTS trungtamngoaingu
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;
USE trungtamngoaingu;

CREATE TABLE IF NOT EXISTS hoc_vien (
      ma_hv      VARCHAR(10)  NOT NULL,
      ho_ten     VARCHAR(100) NOT NULL,
      ngay_sinh  DATE         NOT NULL,
      gioi_tinh  VARCHAR(10)  NOT NULL,
      dia_chi    VARCHAR(255),
      sdt        VARCHAR(20)  NOT NULL,
      email      VARCHAR(100) NOT NULL,
      trang_thai VARCHAR(20)  NOT NULL DEFAULT 'Dang hoc',
      ngay_tao   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,

      PRIMARY KEY (ma_hv),
      CONSTRAINT uq_hv_sdt   UNIQUE (sdt),
      CONSTRAINT uq_hv_email UNIQUE (email),

      CONSTRAINT ck_hv_ma         CHECK (REGEXP_LIKE(ma_hv, '^HV[0-9]{2,8}$', 'c')),
      CONSTRAINT ck_hv_ten        CHECK (CHAR_LENGTH(ho_ten) BETWEEN 2 AND 100
          AND ho_ten = TRIM(ho_ten)
          AND ho_ten NOT REGEXP '[0-9]'),
    CONSTRAINT ck_hv_ngay_sinh  CHECK (ngay_sinh >= '1900-01-01'),
    CONSTRAINT ck_hv_gioi_tinh  CHECK (gioi_tinh IN ('Nam','Nu','Khac')),
    CONSTRAINT ck_hv_sdt        CHECK (sdt REGEXP '^0[0-9]{9}$'),
    CONSTRAINT ck_hv_email      CHECK (email REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$'),
    CONSTRAINT ck_hv_trang_thai CHECK (trang_thai IN ('Dang hoc','Bao luu','Da nghi','Da tot nghiep'))
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS giao_vien (
   ma_gv        VARCHAR(10)  NOT NULL,
   ho_ten       VARCHAR(100) NOT NULL,
   ngay_sinh    DATE         NOT NULL,
   gioi_tinh    VARCHAR(10)  NOT NULL,
   trinh_do     VARCHAR(30)  NOT NULL,
   ngay_vao_lam DATE         NOT NULL,
   loai_hop_dong VARCHAR(50) NOT NULL,
   sdt          VARCHAR(20)  NOT NULL,
   email        VARCHAR(100) NOT NULL,
   trang_thai   VARCHAR(20)  NOT NULL DEFAULT 'Dang day',
   ngay_tao     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,

   PRIMARY KEY (ma_gv),
   CONSTRAINT uq_gv_sdt   UNIQUE (sdt),
   CONSTRAINT uq_gv_email UNIQUE (email),

   CONSTRAINT ck_gv_ma           CHECK (REGEXP_LIKE(ma_gv, '^GV[0-9]{2,8}$', 'c')),
   CONSTRAINT ck_gv_ten          CHECK (CHAR_LENGTH(ho_ten) BETWEEN 2 AND 100
       AND ho_ten = TRIM(ho_ten)
       AND ho_ten NOT REGEXP '[0-9]'),
    CONSTRAINT ck_gv_ngay_sinh    CHECK (ngay_sinh >= '1900-01-01'),
    CONSTRAINT ck_gv_gioi_tinh    CHECK (gioi_tinh IN ('Nam','Nu','Khac')),
    CONSTRAINT ck_gv_trinh_do     CHECK (trinh_do IN ('Cao dang','Dai hoc','Thac si','Tien si','Chung chi','Khac')),
    CONSTRAINT ck_gv_ngay_vao_lam CHECK (ngay_vao_lam >= '2000-01-01'),
    CONSTRAINT ck_gv_du_18_tuoi   CHECK (ngay_vao_lam >= DATE_ADD(ngay_sinh, INTERVAL 18 YEAR)),
    CONSTRAINT ck_gv_loai_hop_dong CHECK (loai_hop_dong IN ('Toan thoi gian','Ban thoi gian','Thinh giang','Thu viec','Cong tac vien')),
    CONSTRAINT ck_gv_sdt          CHECK (sdt REGEXP '^0[0-9]{9}$'),
    CONSTRAINT ck_gv_email        CHECK (email REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$'),
    CONSTRAINT ck_gv_trang_thai   CHECK (trang_thai IN ('Dang day','Tam nghi','Da nghi viec'))
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS khoa_hoc (
      ma_kh            VARCHAR(10)   NOT NULL,
      ten_khoa_hoc     VARCHAR(100)  NOT NULL,
      mo_ta            VARCHAR(500),
      hoc_phi_mac_dinh DECIMAL(12,2) NOT NULL,
      thoi_luong       SMALLINT      NOT NULL,
      trang_thai       VARCHAR(20)   NOT NULL DEFAULT 'Dang mo',

      PRIMARY KEY (ma_kh),
      CONSTRAINT uq_kh_ten UNIQUE (ten_khoa_hoc),

      CONSTRAINT ck_kh_ma         CHECK (REGEXP_LIKE(ma_kh, '^KH[0-9]{2,8}$', 'c')),
      CONSTRAINT ck_kh_ten        CHECK (CHAR_LENGTH(ten_khoa_hoc) BETWEEN 2 AND 100
          AND ten_khoa_hoc = TRIM(ten_khoa_hoc)),
      CONSTRAINT ck_kh_hoc_phi    CHECK (hoc_phi_mac_dinh >= 0),
      CONSTRAINT ck_kh_thoi_luong CHECK (thoi_luong BETWEEN 1 AND 1000),
      CONSTRAINT ck_kh_trang_thai CHECK (trang_thai IN ('Dang mo','Tam dung','Da dong'))
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS lop_hoc (
     ma_lop          VARCHAR(10)  NOT NULL,
     ten_lop         VARCHAR(100) NOT NULL,
     ma_gv           VARCHAR(10)  NOT NULL,
     ma_kh           VARCHAR(10)  NOT NULL,
     ngay_khai_giang DATE         NOT NULL,
     ngay_ket_thuc   DATE         NOT NULL,
     si_so_toi_da    SMALLINT     NOT NULL,
     phong_hoc       VARCHAR(30)  NOT NULL,
     trang_thai      VARCHAR(20)  NOT NULL DEFAULT 'Chua khai giang',

     PRIMARY KEY (ma_lop),
     CONSTRAINT uq_lop_ten UNIQUE (ten_lop),
     CONSTRAINT fk_lop_gv FOREIGN KEY (ma_gv) REFERENCES giao_vien(ma_gv),
     CONSTRAINT fk_lop_kh FOREIGN KEY (ma_kh) REFERENCES khoa_hoc(ma_kh),

     CONSTRAINT ck_lop_ma         CHECK (REGEXP_LIKE(ma_lop, '^LP[0-9]{2,8}$', 'c')),
     CONSTRAINT ck_lop_ten        CHECK (CHAR_LENGTH(ten_lop) BETWEEN 2 AND 100
         AND ten_lop = TRIM(ten_lop)),
     CONSTRAINT ck_lop_khai_giang CHECK (ngay_khai_giang >= '2000-01-01'),
     CONSTRAINT ck_lop_ngay       CHECK (ngay_ket_thuc >= ngay_khai_giang),
     CONSTRAINT ck_lop_si_so      CHECK (si_so_toi_da BETWEEN 1 AND 200),
     CONSTRAINT ck_lop_phong      CHECK (CHAR_LENGTH(TRIM(phong_hoc)) > 0),
     CONSTRAINT ck_lop_trang_thai CHECK (trang_thai IN ('Chua khai giang','Dang hoc','Da ket thuc','Da huy'))
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS ghi_danh (
      ma_hv         VARCHAR(10)   NOT NULL,
      ma_lop        VARCHAR(10)   NOT NULL,
      ngay_dang_ky  DATE          NOT NULL,
      trang_thai_dk VARCHAR(20)   NOT NULL DEFAULT 'Dang ky',
      hoc_phi       DECIMAL(12,2) NOT NULL,

      PRIMARY KEY (ma_hv, ma_lop),
      CONSTRAINT fk_gd_hv  FOREIGN KEY (ma_hv)  REFERENCES hoc_vien(ma_hv),
      CONSTRAINT fk_gd_lop FOREIGN KEY (ma_lop) REFERENCES lop_hoc(ma_lop),

      CONSTRAINT ck_gd_ngay       CHECK (ngay_dang_ky >= '2000-01-01'),
      CONSTRAINT ck_gd_trang_thai CHECK (trang_thai_dk IN ('Dang ky','Dang hoc','Bao luu','Hoan thanh','Huy')),
      CONSTRAINT ck_gd_hoc_phi    CHECK (hoc_phi >= 0)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS hoc_phi (
     ma_hp      VARCHAR(10)   NOT NULL,
     ma_hv      VARCHAR(10)   NOT NULL,
     ma_lop     VARCHAR(10)   NOT NULL,
     so_tien    DECIMAL(12,2) NOT NULL,
     con_no     DECIMAL(12,2) NOT NULL,
     ngay_tao   DATE          NOT NULL,
     trang_thai VARCHAR(20)   NOT NULL DEFAULT 'Chua thanh toan',

     PRIMARY KEY (ma_hp),
     CONSTRAINT uq_hp_ghi_danh UNIQUE (ma_hv, ma_lop),

     CONSTRAINT fk_hp_ghi_danh FOREIGN KEY (ma_hv, ma_lop) REFERENCES ghi_danh(ma_hv, ma_lop),

     CONSTRAINT ck_hp_ma         CHECK (REGEXP_LIKE(ma_hp, '^HP[0-9]{2,8}$', 'c')),
     CONSTRAINT ck_hp_so_tien    CHECK (so_tien >= 0),
     CONSTRAINT ck_hp_con_no     CHECK (con_no >= 0 AND con_no <= so_tien),
     CONSTRAINT ck_hp_ngay_tao   CHECK (ngay_tao >= '2000-01-01'),
     CONSTRAINT ck_hp_trang_thai CHECK (trang_thai IN ('Chua thanh toan','Thanh toan mot phan','Da thanh toan'))
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS dot_dong_hoc_phi (
      ma_dot            VARCHAR(10)   NOT NULL,
      ma_hp             VARCHAR(10)   NOT NULL,
      so_thu_tu         TINYINT       NOT NULL,
      so_tien_phai_dong DECIMAL(12,2) NOT NULL,
      han_dong          DATE          NOT NULL,
      so_tien_da_dong   DECIMAL(12,2) NOT NULL DEFAULT 0,
      trang_thai        VARCHAR(20)   NOT NULL DEFAULT 'Chua dong',

      PRIMARY KEY (ma_dot),
      CONSTRAINT uq_dot_stt UNIQUE (ma_hp, so_thu_tu),
      CONSTRAINT fk_dot_hp FOREIGN KEY (ma_hp) REFERENCES hoc_phi(ma_hp),

      CONSTRAINT ck_dot_ma         CHECK (REGEXP_LIKE(ma_dot, '^DT[0-9]{2,8}$', 'c')),
      CONSTRAINT ck_dot_stt        CHECK (so_thu_tu BETWEEN 1 AND 12),
      CONSTRAINT ck_dot_phai_dong  CHECK (so_tien_phai_dong > 0),
      CONSTRAINT ck_dot_han        CHECK (han_dong >= '2000-01-01'),
      CONSTRAINT ck_dot_da_dong    CHECK (so_tien_da_dong >= 0 AND so_tien_da_dong <= so_tien_phai_dong),
      CONSTRAINT ck_dot_trang_thai CHECK (trang_thai IN ('Chua dong','Dong mot phan','Da dong'))
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS phieu_thu (
       ma_pt       VARCHAR(10)   NOT NULL,
       ma_dot      VARCHAR(10)   NOT NULL,
       ngay_thu    DATE          NOT NULL,
       so_tien_thu DECIMAL(12,2) NOT NULL,
       hinh_thuc   VARCHAR(20)   NOT NULL DEFAULT 'Tien mat',
       ghi_chu     VARCHAR(255),

       PRIMARY KEY (ma_pt),
       CONSTRAINT fk_pt_dot FOREIGN KEY (ma_dot) REFERENCES dot_dong_hoc_phi(ma_dot),

       CONSTRAINT ck_pt_ma        CHECK (REGEXP_LIKE(ma_pt, '^PT[0-9]{2,8}$', 'c')),
       CONSTRAINT ck_pt_ngay      CHECK (ngay_thu >= '2000-01-01'),
       CONSTRAINT ck_pt_so_tien   CHECK (so_tien_thu > 0),
       CONSTRAINT ck_pt_hinh_thuc CHECK (hinh_thuc IN ('Tien mat','Chuyen khoan','The','Vi dien tu'))
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS diem_danh (
       ma_dd          VARCHAR(10) NOT NULL,
       ma_hv          VARCHAR(10) NOT NULL,
       ma_lop         VARCHAR(10) NOT NULL,
       ngay_diem_danh DATE        NOT NULL,
       trang_thai     VARCHAR(20) NOT NULL DEFAULT 'Co mat',
       ghi_chu        VARCHAR(255),

       PRIMARY KEY (ma_dd),
       CONSTRAINT uq_dd_mot_buoi UNIQUE (ma_hv, ma_lop, ngay_diem_danh),

       CONSTRAINT fk_dd_ghi_danh FOREIGN KEY (ma_hv, ma_lop) REFERENCES ghi_danh(ma_hv, ma_lop),

       CONSTRAINT ck_dd_ma         CHECK (REGEXP_LIKE(ma_dd, '^DD[0-9]{2,8}$', 'c')),
       CONSTRAINT ck_dd_ngay       CHECK (ngay_diem_danh >= '2000-01-01'),
       CONSTRAINT ck_dd_trang_thai CHECK (trang_thai IN ('Co mat','Vang','Muon','Co phep'))
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS diem_so (
     ma_diem         VARCHAR(10) NOT NULL,
     ma_hv           VARCHAR(10) NOT NULL,
     ma_lop          VARCHAR(10) NOT NULL,
     diem_giua_ky    DECIMAL(4,2),
     diem_cuoi_ky    DECIMAL(4,2),
     diem_trung_binh DECIMAL(4,2),
     nhan_xet        VARCHAR(255),

     PRIMARY KEY (ma_diem),
     CONSTRAINT uq_ds_hv_lop UNIQUE (ma_hv, ma_lop),
     CONSTRAINT fk_ds_ghi_danh FOREIGN KEY (ma_hv, ma_lop) REFERENCES ghi_danh(ma_hv, ma_lop),

     CONSTRAINT ck_ds_ma  CHECK (REGEXP_LIKE(ma_diem, '^DS[0-9]{2,8}$', 'c')),
     CONSTRAINT ck_ds_gk  CHECK (diem_giua_ky    IS NULL OR diem_giua_ky    BETWEEN 0 AND 10),
     CONSTRAINT ck_ds_ck  CHECK (diem_cuoi_ky    IS NULL OR diem_cuoi_ky    BETWEEN 0 AND 10),
     CONSTRAINT ck_ds_tb  CHECK (diem_trung_binh IS NULL OR diem_trung_binh BETWEEN 0 AND 10)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS tai_khoan (
   ten_dang_nhap VARCHAR(50)  NOT NULL,
   mat_khau      VARCHAR(255) NOT NULL,
   vai_tro       VARCHAR(20)  NOT NULL DEFAULT 'Giao vu',
   trang_thai    VARCHAR(15)  NOT NULL DEFAULT 'Hoat dong',
   ngay_tao      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,

   PRIMARY KEY (ten_dang_nhap),

   CONSTRAINT ck_tk_ten        CHECK (ten_dang_nhap REGEXP '^[A-Za-z0-9_.-]{4,50}$'),
    CONSTRAINT ck_tk_mat_khau   CHECK (CHAR_LENGTH(mat_khau) >= 32),
    CONSTRAINT ck_tk_vai_tro    CHECK (vai_tro IN ('Admin','Giao vu','Giao vien','Ke toan','Hoc vien')),
    CONSTRAINT ck_tk_trang_thai CHECK (trang_thai IN ('Hoat dong','Bi khoa'))
) ENGINE=InnoDB;

DROP PROCEDURE IF EXISTS sp_tao_index;
DELIMITER $$
CREATE PROCEDURE sp_tao_index(p_bang VARCHAR(64), p_ten VARCHAR(64), p_cot VARCHAR(255))
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.STATISTICS
                   WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = p_bang AND INDEX_NAME = p_ten) THEN
        SET @sql = CONCAT('CREATE INDEX ', p_ten, ' ON ', p_bang, ' (', p_cot, ')');
        PREPARE st FROM @sql; EXECUTE st; DEALLOCATE PREPARE st;
    END IF;
END$$
DELIMITER ;
CALL sp_tao_index('hoc_vien', 'idx_hv_ho_ten', 'ho_ten');
CALL sp_tao_index('giao_vien', 'idx_gv_ho_ten', 'ho_ten');
CALL sp_tao_index('lop_hoc', 'idx_lop_trang_thai', 'trang_thai, ngay_khai_giang');
CALL sp_tao_index('ghi_danh', 'idx_gd_trang_thai', 'ma_lop, trang_thai_dk');
CALL sp_tao_index('hoc_phi', 'idx_hp_trang_thai', 'trang_thai');
CALL sp_tao_index('dot_dong_hoc_phi', 'idx_dot_han', 'han_dong, trang_thai');
CALL sp_tao_index('phieu_thu', 'idx_pt_ngay', 'ngay_thu');
CALL sp_tao_index('diem_danh', 'idx_dd_lop_ngay', 'ma_lop, ngay_diem_danh');
DROP PROCEDURE sp_tao_index;

DELIMITER $$

DROP TRIGGER IF EXISTS trg_hv_bi$$

CREATE TRIGGER trg_hv_bi BEFORE INSERT ON hoc_vien FOR EACH ROW
BEGIN
    IF NEW.ngay_sinh > CURDATE() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ngay sinh hoc vien khong duoc o tuong lai';
END IF;
END$$

DROP TRIGGER IF EXISTS trg_hv_bu$$

CREATE TRIGGER trg_hv_bu BEFORE UPDATE ON hoc_vien FOR EACH ROW
BEGIN
    IF NEW.ngay_sinh > CURDATE() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ngay sinh hoc vien khong duoc o tuong lai';
END IF;
END$$

DROP TRIGGER IF EXISTS trg_gv_bi$$

CREATE TRIGGER trg_gv_bi BEFORE INSERT ON giao_vien FOR EACH ROW
BEGIN
    IF NEW.ngay_sinh > CURDATE() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ngay sinh giao vien khong duoc o tuong lai';
END IF;
IF NEW.ngay_vao_lam > CURDATE() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ngay vao lam khong duoc o tuong lai';
END IF;
END$$

DROP TRIGGER IF EXISTS trg_gv_bu$$

CREATE TRIGGER trg_gv_bu BEFORE UPDATE ON giao_vien FOR EACH ROW
BEGIN
    IF NEW.ngay_sinh > CURDATE() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ngay sinh giao vien khong duoc o tuong lai';
END IF;
IF NEW.ngay_vao_lam > CURDATE() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ngay vao lam khong duoc o tuong lai';
END IF;
END$$

DROP TRIGGER IF EXISTS trg_lop_bi$$

CREATE TRIGGER trg_lop_bi BEFORE INSERT ON lop_hoc FOR EACH ROW
BEGIN
    DECLARE v_tt_gv VARCHAR(20);
    DECLARE v_tt_kh VARCHAR(20);

    SELECT trang_thai INTO v_tt_gv FROM giao_vien WHERE ma_gv = NEW.ma_gv;
    SELECT trang_thai INTO v_tt_kh FROM khoa_hoc  WHERE ma_kh = NEW.ma_kh;

    IF v_tt_gv IS NOT NULL AND v_tt_gv <> 'Dang day' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Giao vien khong o trang thai Dang day, khong the phan cong lop';
END IF;
IF v_tt_kh IS NOT NULL AND v_tt_kh <> 'Dang mo' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Khoa hoc khong o trang thai Dang mo, khong the mo lop';
END IF;
END$$

DROP TRIGGER IF EXISTS trg_gd_bi$$

CREATE TRIGGER trg_gd_bi BEFORE INSERT ON ghi_danh FOR EACH ROW
BEGIN
    DECLARE v_tt_lop VARCHAR(20);
    DECLARE v_max    INT;
    DECLARE v_dang   INT;
    DECLARE v_tt_hv  VARCHAR(20);

    IF NEW.ngay_dang_ky > CURDATE() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ngay dang ky khong duoc o tuong lai';
END IF;

SELECT trang_thai, si_so_toi_da INTO v_tt_lop, v_max
FROM lop_hoc WHERE ma_lop = NEW.ma_lop;
IF v_tt_lop IN ('Da ket thuc','Da huy') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lop da ket thuc hoac da huy, khong nhan ghi danh';
END IF;

SELECT trang_thai INTO v_tt_hv FROM hoc_vien WHERE ma_hv = NEW.ma_hv;
IF v_tt_hv IN ('Da nghi','Bao luu') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Hoc vien dang bao luu hoac da nghi, khong the ghi danh';
END IF;

    IF v_max IS NOT NULL AND NEW.trang_thai_dk IN ('Dang ky','Dang hoc') THEN
SELECT COUNT(*) INTO v_dang
FROM ghi_danh
WHERE ma_lop = NEW.ma_lop AND trang_thai_dk IN ('Dang ky','Dang hoc');
IF v_dang >= v_max THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lop da du si so toi da';
END IF;
END IF;
END$$

DROP TRIGGER IF EXISTS trg_hp_bi$$

CREATE TRIGGER trg_hp_bi BEFORE INSERT ON hoc_phi FOR EACH ROW
BEGIN
    IF NEW.ngay_tao > CURDATE() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ngay tao hoc phi khong duoc o tuong lai';
END IF;
SET NEW.trang_thai = CASE
        WHEN NEW.con_no = 0              THEN 'Da thanh toan'
        WHEN NEW.con_no < NEW.so_tien    THEN 'Thanh toan mot phan'
        ELSE 'Chua thanh toan'
END;
END$$

DROP TRIGGER IF EXISTS trg_hp_bu$$

CREATE TRIGGER trg_hp_bu BEFORE UPDATE ON hoc_phi FOR EACH ROW
BEGIN
    DECLARE v_da_chia DECIMAL(12,2);

    IF NEW.so_tien <> OLD.so_tien THEN
    SELECT COALESCE(SUM(so_tien_phai_dong), 0) INTO v_da_chia
    FROM dot_dong_hoc_phi WHERE ma_hp = NEW.ma_hp;
    IF NEW.so_tien < v_da_chia THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tong hoc phi khong duoc nho hon tong cac dot da chia';
END IF;
END IF;

    SET NEW.trang_thai = CASE
        WHEN NEW.con_no = 0              THEN 'Da thanh toan'
        WHEN NEW.con_no < NEW.so_tien    THEN 'Thanh toan mot phan'
        ELSE 'Chua thanh toan'
END;
END$$

DROP TRIGGER IF EXISTS trg_dot_bi$$

CREATE TRIGGER trg_dot_bi BEFORE INSERT ON dot_dong_hoc_phi FOR EACH ROW
BEGIN
    DECLARE v_tong     DECIMAL(12,2);
    DECLARE v_ngay_tao DATE;
    DECLARE v_da_chia  DECIMAL(12,2);
    DECLARE v_han_truoc DATE;

    SELECT so_tien, ngay_tao INTO v_tong, v_ngay_tao FROM hoc_phi WHERE ma_hp = NEW.ma_hp;

    IF v_tong IS NOT NULL THEN
        IF NEW.han_dong < v_ngay_tao THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Han dong khong duoc truoc ngay tao hoc phi';
END IF;

SELECT COALESCE(SUM(so_tien_phai_dong), 0) INTO v_da_chia
FROM dot_dong_hoc_phi WHERE ma_hp = NEW.ma_hp;
IF v_da_chia + NEW.so_tien_phai_dong > v_tong THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tong cac dot vuot qua tong hoc phi';
END IF;

SELECT MAX(han_dong) INTO v_han_truoc
FROM dot_dong_hoc_phi WHERE ma_hp = NEW.ma_hp AND so_thu_tu < NEW.so_thu_tu;
IF v_han_truoc IS NOT NULL AND NEW.han_dong < v_han_truoc THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Han dong cua dot sau khong duoc som hon dot truoc';
END IF;
END IF;

    SET NEW.so_tien_da_dong = 0;
    SET NEW.trang_thai = 'Chua dong';
END$$

DROP TRIGGER IF EXISTS trg_dot_bu$$

CREATE TRIGGER trg_dot_bu BEFORE UPDATE ON dot_dong_hoc_phi FOR EACH ROW
BEGIN
    DECLARE v_tong    DECIMAL(12,2);
    DECLARE v_cac_dot DECIMAL(12,2);

    IF NEW.so_tien_phai_dong <> OLD.so_tien_phai_dong THEN
    SELECT so_tien INTO v_tong FROM hoc_phi WHERE ma_hp = NEW.ma_hp;
    SELECT COALESCE(SUM(so_tien_phai_dong), 0) INTO v_cac_dot
    FROM dot_dong_hoc_phi WHERE ma_hp = NEW.ma_hp AND ma_dot <> NEW.ma_dot;
    IF v_cac_dot + NEW.so_tien_phai_dong > v_tong THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tong cac dot vuot qua tong hoc phi';
END IF;
END IF;

    SET NEW.trang_thai = CASE
        WHEN NEW.so_tien_da_dong = 0                      THEN 'Chua dong'
        WHEN NEW.so_tien_da_dong < NEW.so_tien_phai_dong  THEN 'Dong mot phan'
        ELSE 'Da dong'
END;
END$$

DROP TRIGGER IF EXISTS trg_pt_bi$$

CREATE TRIGGER trg_pt_bi BEFORE INSERT ON phieu_thu FOR EACH ROW
BEGIN
    DECLARE v_con_lai  DECIMAL(12,2);
    DECLARE v_ngay_tao DATE;

    IF NEW.ngay_thu > CURDATE() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ngay thu khong duoc o tuong lai';
END IF;

SELECT d.so_tien_phai_dong - d.so_tien_da_dong, hp.ngay_tao
INTO v_con_lai, v_ngay_tao
FROM dot_dong_hoc_phi d
         JOIN hoc_phi hp ON hp.ma_hp = d.ma_hp
WHERE d.ma_dot = NEW.ma_dot;

IF v_con_lai IS NOT NULL AND NEW.so_tien_thu > v_con_lai THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'So tien thu vuot qua so tien con lai cua dot nay';
END IF;
    IF v_ngay_tao IS NOT NULL AND NEW.ngay_thu < v_ngay_tao THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ngay thu khong duoc truoc ngay tao hoc phi';
END IF;
END$$

DROP TRIGGER IF EXISTS trg_pt_ai$$

CREATE TRIGGER trg_pt_ai AFTER INSERT ON phieu_thu FOR EACH ROW
BEGIN
    DECLARE v_hp VARCHAR(10);

    UPDATE dot_dong_hoc_phi
    SET so_tien_da_dong = so_tien_da_dong + NEW.so_tien_thu
    WHERE ma_dot = NEW.ma_dot;

    SELECT ma_hp INTO v_hp FROM dot_dong_hoc_phi WHERE ma_dot = NEW.ma_dot;
    UPDATE hoc_phi SET con_no = con_no - NEW.so_tien_thu WHERE ma_hp = v_hp;
    END$$

    DROP TRIGGER IF EXISTS trg_pt_bu$$

    CREATE TRIGGER trg_pt_bu BEFORE UPDATE ON phieu_thu FOR EACH ROW
    BEGIN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Phieu thu da lap khong duoc sua';
END$$

        DROP TRIGGER IF EXISTS trg_pt_bd$$

        CREATE TRIGGER trg_pt_bd BEFORE DELETE ON phieu_thu FOR EACH ROW
        BEGIN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Phieu thu da lap khong duoc xoa';
END$$

            DROP TRIGGER IF EXISTS trg_dd_bi$$

            CREATE TRIGGER trg_dd_bi BEFORE INSERT ON diem_danh FOR EACH ROW
            BEGIN
                DECLARE v_bd DATE;
    DECLARE v_kt DATE;

    IF NEW.ngay_diem_danh > CURDATE() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Khong duoc diem danh cho ngay trong tuong lai';
            END IF;

            SELECT ngay_khai_giang, ngay_ket_thuc INTO v_bd, v_kt
            FROM lop_hoc WHERE ma_lop = NEW.ma_lop;
            IF v_bd IS NOT NULL AND (NEW.ngay_diem_danh < v_bd OR NEW.ngay_diem_danh > v_kt) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ngay diem danh nam ngoai thoi gian hoc cua lop';
        END IF;
        END$$

        DROP TRIGGER IF EXISTS trg_ds_bi$$

        CREATE TRIGGER trg_ds_bi BEFORE INSERT ON diem_so FOR EACH ROW
        BEGIN
            SET NEW.diem_trung_binh = IF(NEW.diem_giua_ky IS NULL OR NEW.diem_cuoi_ky IS NULL,
                                 NULL,
                                 ROUND(NEW.diem_giua_ky * 0.4 + NEW.diem_cuoi_ky * 0.6, 2));
END$$

            DROP TRIGGER IF EXISTS trg_ds_bu$$

            CREATE TRIGGER trg_ds_bu BEFORE UPDATE ON diem_so FOR EACH ROW
            BEGIN
                SET NEW.diem_trung_binh = IF(NEW.diem_giua_ky IS NULL OR NEW.diem_cuoi_ky IS NULL,
                                 NULL,
                                 ROUND(NEW.diem_giua_ky * 0.4 + NEW.diem_cuoi_ky * 0.6, 2));
END$$

                DELIMITER ;

                CREATE OR REPLACE VIEW v_si_so_lop AS
                SELECT lh.ma_lop,
                       lh.ten_lop,
                       kh.ten_khoa_hoc,
                       gv.ho_ten                              AS giao_vien,
                       lh.phong_hoc,
                       lh.trang_thai,
                       COUNT(gd.ma_hv)                        AS si_so_hien_tai,
                       lh.si_so_toi_da,
                       lh.si_so_toi_da - COUNT(gd.ma_hv)      AS con_trong
                FROM lop_hoc lh
                         JOIN khoa_hoc  kh ON kh.ma_kh = lh.ma_kh
                         JOIN giao_vien gv ON gv.ma_gv = lh.ma_gv
                         LEFT JOIN ghi_danh gd
                                   ON gd.ma_lop = lh.ma_lop AND gd.trang_thai_dk IN ('Dang ky','Dang hoc')
                GROUP BY lh.ma_lop, lh.ten_lop, kh.ten_khoa_hoc, gv.ho_ten,
                         lh.phong_hoc, lh.trang_thai, lh.si_so_toi_da;

                CREATE OR REPLACE VIEW v_cong_no AS
                SELECT hp.ma_hp,
                       hv.ma_hv,
                       hv.ho_ten,
                       lh.ten_lop,
                       hp.so_tien                    AS tong_hoc_phi,
                       hp.so_tien - hp.con_no        AS da_thu,
                       hp.con_no,
                       hp.trang_thai
                FROM hoc_phi hp
                         JOIN hoc_vien hv ON hv.ma_hv  = hp.ma_hv
                         JOIN lop_hoc  lh ON lh.ma_lop = hp.ma_lop;

                CREATE OR REPLACE VIEW v_hoc_phi_hoc_vien AS
                SELECT hv.ma_hv                                                  AS `Mã HV`,
                       hv.ho_ten                                                 AS `Họ và tên`,
                       lh.ten_lop                                                AS `Lớp`,
                       CONCAT(FORMAT(hp.so_tien, 0, 'de_DE'), 'đ')               AS `Học phí`,
                       CONCAT(FORMAT(hp.so_tien - hp.con_no, 0, 'de_DE'), 'đ')   AS `Đã đóng`,
                       CONCAT(FORMAT(hp.con_no, 0, 'de_DE'), 'đ')                AS `Còn nợ`,
                       (CASE WHEN hp.con_no = 0 THEN 'Đã thanh toán' ELSE 'Còn nợ' END) COLLATE utf8mb4_unicode_ci AS `Trạng thái`
                FROM hoc_phi hp
                         JOIN hoc_vien hv ON hv.ma_hv  = hp.ma_hv
                         JOIN lop_hoc  lh ON lh.ma_lop = hp.ma_lop
                ORDER BY hv.ma_hv, lh.ma_lop;

                CREATE OR REPLACE VIEW v_dot_dong_hoc_phi AS
                SELECT d.ma_dot,
                       hp.ma_hp,
                       hv.ma_hv,
                       hv.ho_ten,
                       lh.ten_lop,
                       d.so_thu_tu                                        AS dot_thu,
                       d.so_tien_phai_dong,
                       d.so_tien_da_dong,
                       d.so_tien_phai_dong - d.so_tien_da_dong            AS con_lai,
                       d.han_dong,
                       d.trang_thai,
                       (CASE
                           WHEN d.so_tien_da_dong >= d.so_tien_phai_dong THEN 'Da xong'
                           WHEN d.han_dong < CURDATE()                    THEN 'Qua han'
                           ELSE 'Trong han'
                           END) COLLATE utf8mb4_unicode_ci                    AS tinh_trang_han
                FROM dot_dong_hoc_phi d
                         JOIN hoc_phi  hp ON hp.ma_hp  = d.ma_hp
                         JOIN hoc_vien hv ON hv.ma_hv  = hp.ma_hv
                         JOIN lop_hoc  lh ON lh.ma_lop = hp.ma_lop;

                CREATE OR REPLACE VIEW v_lich_su_thu_tien AS
                SELECT pt.ma_pt,
                       pt.ngay_thu,
                       hv.ho_ten,
                       lh.ten_lop,
                       d.so_thu_tu     AS dot_thu,
                       pt.so_tien_thu,
                       pt.hinh_thuc,
                       pt.ghi_chu
                FROM phieu_thu pt
                         JOIN dot_dong_hoc_phi d ON d.ma_dot = pt.ma_dot
                         JOIN hoc_phi  hp ON hp.ma_hp  = d.ma_hp
                         JOIN hoc_vien hv ON hv.ma_hv  = hp.ma_hv
                         JOIN lop_hoc  lh ON lh.ma_lop = hp.ma_lop;

                CREATE OR REPLACE VIEW v_bang_diem AS
                SELECT hv.ma_hv,
                       hv.ho_ten,
                       lh.ten_lop,
                       ds.diem_giua_ky,
                       ds.diem_cuoi_ky,
                       ds.diem_trung_binh,
                       (CASE
                           WHEN ds.diem_trung_binh IS NULL THEN 'Chua du diem'
                           WHEN ds.diem_trung_binh >= 8.5  THEN 'Gioi'
                           WHEN ds.diem_trung_binh >= 7.0  THEN 'Kha'
                           WHEN ds.diem_trung_binh >= 5.0  THEN 'Trung binh'
                           ELSE 'Yeu'
                           END) COLLATE utf8mb4_unicode_ci AS xep_loai
                FROM diem_so ds
                         JOIN hoc_vien hv ON hv.ma_hv  = ds.ma_hv
                         JOIN lop_hoc  lh ON lh.ma_lop = ds.ma_lop;

                CREATE OR REPLACE VIEW v_chuyen_can AS
                SELECT hv.ma_hv,
                       hv.ho_ten,
                       lh.ten_lop,
                       COUNT(*)                                                    AS tong_buoi,
                       SUM(dd.trang_thai IN ('Co mat','Muon'))                     AS so_buoi_di_hoc,
                       SUM(dd.trang_thai = 'Co phep')                              AS so_buoi_co_phep,
                       SUM(dd.trang_thai = 'Vang')                                 AS so_buoi_vang,
                       ROUND(100 * SUM(dd.trang_thai IN ('Co mat','Muon')) / COUNT(*), 1) AS ty_le_chuyen_can_pct
                FROM diem_danh dd
                         JOIN hoc_vien hv ON hv.ma_hv  = dd.ma_hv
                         JOIN lop_hoc  lh ON lh.ma_lop = dd.ma_lop
                GROUP BY hv.ma_hv, hv.ho_ten, lh.ten_lop;

-- Dữ liệu mẫu: chỉ nạp khi CSDL còn trống (lần chạy đầu tiên)
DROP PROCEDURE IF EXISTS sp_nap_du_lieu_mau;
DELIMITER $$
CREATE PROCEDURE sp_nap_du_lieu_mau()
BEGIN
    IF (SELECT COUNT(*) FROM hoc_vien) = 0 THEN
                INSERT INTO hoc_vien (ma_hv, ho_ten, ngay_sinh, gioi_tinh, dia_chi, sdt, email, trang_thai) VALUES
                                                                                                                ('HV01','Nguyen Van A','2005-01-01','Nam', 'Cau Giay, Ha Noi',  '0911111111','a@gmail.com','Dang hoc'),
                                                                                                                ('HV02','Tran Thi B',  '2005-03-15','Nu',  'Hai Phong',         '0922222222','b@gmail.com','Dang hoc'),
                                                                                                                ('HV03','Le Van C',    '2004-07-20','Khac','Hai Chau, Da Nang', '0933333333','c@gmail.com','Dang hoc');

                INSERT INTO giao_vien (ma_gv, ho_ten, ngay_sinh, gioi_tinh, trinh_do, ngay_vao_lam, loai_hop_dong, sdt, email, trang_thai) VALUES
                                                                                                                                               ('GV01','Nguyen Van Teacher','1985-04-10','Nam','Thac si','2015-09-01','Toan thoi gian','0900000001','teacher1@gmail.com','Dang day'),
                                                                                                                                               ('GV02','Tran Teacher',       '1990-06-12','Nu', 'Dai hoc','2018-03-01','Ban thoi gian', '0900000002','teacher2@gmail.com','Dang day');

                INSERT INTO khoa_hoc (ma_kh, ten_khoa_hoc, mo_ta, hoc_phi_mac_dinh, thoi_luong, trang_thai) VALUES
                                                                                                                ('KH01','IELTS 6.5',  'Khoa luyen thi IELTS muc tieu 6.5',  5000000, 36, 'Dang mo'),
                                                                                                                ('KH02','TOEIC 700+', 'Khoa luyen thi TOEIC muc tieu 700+', 4000000, 24, 'Dang mo');

                INSERT INTO lop_hoc (ma_lop, ten_lop, ma_gv, ma_kh, ngay_khai_giang, ngay_ket_thuc, si_so_toi_da, phong_hoc, trang_thai) VALUES
                                                                                                                                             ('LP01','IELTS-01','GV01','KH01','2026-09-01','2026-12-15',20,'P101','Dang hoc'),
                                                                                                                                             ('LP02','TOEIC-01','GV02','KH02','2026-09-10','2026-12-20',25,'P102','Dang hoc');

                INSERT INTO ghi_danh (ma_hv, ma_lop, ngay_dang_ky, trang_thai_dk, hoc_phi) VALUES
                                                                                               ('HV01','LP01','2026-08-25','Dang hoc',5000000),
                                                                                               ('HV02','LP01','2026-08-26','Dang hoc',5000000),
                                                                                               ('HV03','LP02','2026-09-01','Dang hoc',4000000);

                INSERT INTO hoc_phi (ma_hp, ma_hv, ma_lop, so_tien, con_no, ngay_tao) VALUES
                                                                                          ('HP01','HV01','LP01',5000000,5000000,'2026-08-25'),
                                                                                          ('HP02','HV02','LP01',5000000,5000000,'2026-08-26'),
                                                                                          ('HP03','HV03','LP02',4000000,4000000,'2026-09-01');

                INSERT INTO dot_dong_hoc_phi (ma_dot, ma_hp, so_thu_tu, so_tien_phai_dong, han_dong) VALUES
                                                                                                         ('DT01','HP01',1,2500000,'2026-08-25'),
                                                                                                         ('DT02','HP01',2,2500000,'2026-09-25'),
                                                                                                         ('DT03','HP02',1,2000000,'2026-08-26'),
                                                                                                         ('DT04','HP02',2,2000000,'2026-09-26'),
                                                                                                         ('DT05','HP02',3,1000000,'2026-10-26'),
                                                                                                         ('DT06','HP03',1,2000000,'2026-09-01'),
                                                                                                         ('DT07','HP03',2,2000000,'2026-11-01');

                INSERT INTO phieu_thu (ma_pt, ma_dot, ngay_thu, so_tien_thu, hinh_thuc, ghi_chu) VALUES
                                                                                                     ('PT01','DT01','2026-08-25',2500000,'Chuyen khoan','Dot 1 - dong du'),
                                                                                                     ('PT02','DT02','2026-09-20',2500000,'Chuyen khoan','Dot 2 - dong du'),
                                                                                                     ('PT03','DT03','2026-08-26',2000000,'Tien mat',    'Dot 1 - dong du'),
                                                                                                     ('PT04','DT04','2026-09-26',2000000,'Tien mat',    'Dot 2 - dong du'),
                                                                                                     ('PT05','DT06','2026-09-01',2000000,'Vi dien tu',  'Dot 1 - dong du'),
                                                                                                     ('PT06','DT07','2026-10-15',1500000,'Vi dien tu',  'Dot 2 - dong mot phan');

                INSERT INTO diem_danh (ma_dd, ma_hv, ma_lop, ngay_diem_danh, trang_thai) VALUES
                                                                                             ('DD01','HV01','LP01','2026-09-01','Co mat'),
                                                                                             ('DD02','HV02','LP01','2026-09-01','Muon'),
                                                                                             ('DD03','HV01','LP01','2026-09-03','Co mat'),
                                                                                             ('DD04','HV02','LP01','2026-09-03','Vang'),
                                                                                             ('DD05','HV03','LP02','2026-09-10','Co mat'),
                                                                                             ('DD06','HV03','LP02','2026-09-12','Co phep');

                INSERT INTO diem_so (ma_diem, ma_hv, ma_lop, diem_giua_ky, diem_cuoi_ky, nhan_xet) VALUES
                                                                                                       ('DS01','HV01','LP01',8.5,9.0,'Tien bo tot'),
                                                                                                       ('DS02','HV02','LP01',7.0,8.0,'Can chu y chuyen can'),
                                                                                                       ('DS03','HV03','LP02',6.5,NULL,'Chua thi cuoi ky');

                INSERT INTO tai_khoan (ten_dang_nhap, mat_khau, vai_tro, trang_thai) VALUES
                                                                                         ('admin01',    SHA2('Admin@123',256),    'Admin',     'Hoat dong'),
                                                                                         ('giaovu01',   SHA2('GiaoVu@123',256),   'Giao vu',   'Hoat dong'),
                                                                                         ('ketoan01',   SHA2('KeToan@123',256),   'Ke toan',   'Hoat dong'),
                                                                                         ('gv_teacher1',SHA2('Teacher@123',256),  'Giao vien', 'Hoat dong');
    END IF;
END$$
DELIMITER ;
CALL sp_nap_du_lieu_mau();
DROP PROCEDURE sp_nap_du_lieu_mau;

SHOW TABLES;

                SELECT hv.ma_hv, hv.ho_ten, lh.ten_lop
                FROM hoc_vien hv
                         JOIN ghi_danh gd ON hv.ma_hv  = gd.ma_hv
                         JOIN lop_hoc  lh ON gd.ma_lop = lh.ma_lop;

                SELECT hv.ho_ten, hp.con_no
                FROM hoc_vien hv
                         JOIN hoc_phi hp ON hv.ma_hv = hp.ma_hv
                WHERE hp.con_no > 0;

                SELECT * FROM hoc_vien  WHERE ho_ten LIKE '%Nguyen%';
                SELECT * FROM giao_vien WHERE ho_ten LIKE '%Tran%';

                SELECT * FROM v_si_so_lop;
                SELECT * FROM v_hoc_phi_hoc_vien;
                SELECT * FROM v_cong_no;
                SELECT * FROM v_dot_dong_hoc_phi;
                SELECT * FROM v_lich_su_thu_tien;
                SELECT * FROM v_bang_diem;
                SELECT * FROM v_chuyen_can;

                SELECT lh.ten_lop, SUM(pt.so_tien_thu) AS tong_da_thu
                FROM phieu_thu pt
                         JOIN dot_dong_hoc_phi d ON d.ma_dot = pt.ma_dot
                         JOIN hoc_phi hp ON hp.ma_hp  = d.ma_hp
                         JOIN lop_hoc lh ON lh.ma_lop = hp.ma_lop
                GROUP BY lh.ten_lop;

                SELECT ho_ten, ten_lop, dot_thu, con_lai, han_dong
                FROM v_dot_dong_hoc_phi
                WHERE tinh_trang_han = 'Qua han';

                SELECT loai_hop_dong, COUNT(*) AS so_giao_vien
                FROM giao_vien
                GROUP BY loai_hop_dong;

-- ===== PHẦN 2: advanced.sql =====
-- =====================================================================
--  advanced.sql  —  PHẦN SQL NÂNG CAO
--  Chạy SAU database.sql:   mysql -u root -p < database.sql
--                           mysql -u root -p < advanced.sql
--
--  Mục lục
--   1. Sửa lỗi nghiệp vụ trong trigger gốc + trigger mới (ghi_danh UPDATE)
--   2. Bảng nhật ký (audit log) + trigger ghi JSON
--   3. Stored function
--   4. Stored procedure có TRANSACTION, khóa dòng (FOR UPDATE), CURSOR,
--      xử lý lỗi (HANDLER / SIGNAL / RESIGNAL), SQL động (PREPARE)
--   5. View nâng cao: CTE, CTE đệ quy, window function
--   6. Truy vấn minh họa: phép chia, EXISTS, ALL/ANY, UNION, ROLLUP, EXPLAIN
--   7. EVENT (tác vụ định kỳ)
--   8. Phân quyền: ROLE, USER, GRANT mức bảng / cột / procedure
--   9. Kịch bản chạy thử + các ca kiểm thử lỗi
-- =====================================================================
-- Cùng collation với bảng (utf8mb4_unicode_ci) để các hằng chuỗi trong view/procedure
-- không bị lỗi "Illegal mix of collations" khi client dùng collation khác.
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;
USE trungtamngoaingu;

-- =====================================================================
-- 1. SỬA LỖI + TRIGGER MỚI
-- =====================================================================
DELIMITER $$

-- 1a. Trigger gốc trg_hp_bu: khi đổi so_tien (giảm giá, phụ thu) thì con_no
--     KHÔNG đổi theo  ->  số nợ sai. Sửa: con_no dịch chuyển cùng chênh lệch.
DROP TRIGGER IF EXISTS trg_hp_bu$$
CREATE TRIGGER trg_hp_bu BEFORE UPDATE ON hoc_phi FOR EACH ROW
BEGIN
    DECLARE v_da_chia DECIMAL(12,2);

    IF NEW.so_tien <> OLD.so_tien THEN
        SELECT COALESCE(SUM(so_tien_phai_dong), 0) INTO v_da_chia
        FROM dot_dong_hoc_phi WHERE ma_hp = NEW.ma_hp;
        IF NEW.so_tien < v_da_chia THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tong hoc phi khong duoc nho hon tong cac dot da chia';
        END IF;
        -- chỉ tự điều chỉnh khi người dùng không tự sửa con_no trong cùng lệnh
        IF NEW.con_no = OLD.con_no THEN
            SET NEW.con_no = OLD.con_no + (NEW.so_tien - OLD.so_tien);
        END IF;
    END IF;

    SET NEW.trang_thai = CASE
        WHEN NEW.con_no = 0           THEN 'Da thanh toan'
        WHEN NEW.con_no < NEW.so_tien THEN 'Thanh toan mot phan'
        ELSE 'Chua thanh toan'
    END;
END$$

-- 1b. Thiếu trigger BEFORE UPDATE cho ghi_danh: có thể đổi 'Huy' -> 'Dang hoc'
--     để lách giới hạn sĩ số, hoặc sửa khóa chính làm mồ côi hoc_phi.
DROP TRIGGER IF EXISTS trg_gd_bu$$
CREATE TRIGGER trg_gd_bu BEFORE UPDATE ON ghi_danh FOR EACH ROW
BEGIN
    DECLARE v_max  INT;
    DECLARE v_dang INT;

    IF NEW.ma_hv <> OLD.ma_hv OR NEW.ma_lop <> OLD.ma_lop THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Khong duoc sua ma hoc vien / ma lop cua ghi danh';
    END IF;

    -- chuyển từ trạng thái "không chiếm chỗ" sang "chiếm chỗ" thì kiểm tra sĩ số
    IF OLD.trang_thai_dk NOT IN ('Dang ky','Dang hoc')
       AND NEW.trang_thai_dk IN ('Dang ky','Dang hoc') THEN
        SELECT si_so_toi_da INTO v_max FROM lop_hoc WHERE ma_lop = NEW.ma_lop;
        SELECT COUNT(*) INTO v_dang
        FROM ghi_danh
        WHERE ma_lop = NEW.ma_lop AND trang_thai_dk IN ('Dang ky','Dang hoc');
        IF v_dang >= v_max THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lop da du si so toi da';
        END IF;
    END IF;
END$$

DELIMITER ;

-- =====================================================================
-- 2. AUDIT LOG  —  ghi lại ai sửa gì, lúc nào (dữ liệu cũ/mới dạng JSON)
-- =====================================================================
CREATE TABLE IF NOT EXISTS nhat_ky_thay_doi (
    id          BIGINT       NOT NULL AUTO_INCREMENT,
    bang        VARCHAR(30)  NOT NULL,
    ma_ban_ghi  VARCHAR(30)  NOT NULL,
    hanh_dong   VARCHAR(10)  NOT NULL,
    du_lieu_cu  JSON,
    du_lieu_moi JSON,
    nguoi_dung  VARCHAR(100) NOT NULL,
    thoi_gian   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    INDEX idx_nk_bang (bang, ma_ban_ghi, thoi_gian),
    CONSTRAINT ck_nk_hanh_dong CHECK (hanh_dong IN ('INSERT','UPDATE','DELETE'))
) ENGINE=InnoDB;

DELIMITER $$

DROP TRIGGER IF EXISTS trg_hv_au_audit$$
CREATE TRIGGER trg_hv_au_audit AFTER UPDATE ON hoc_vien FOR EACH ROW
BEGIN
    INSERT INTO nhat_ky_thay_doi (bang, ma_ban_ghi, hanh_dong, du_lieu_cu, du_lieu_moi, nguoi_dung)
    VALUES ('hoc_vien', OLD.ma_hv, 'UPDATE',
            JSON_OBJECT('ho_ten', OLD.ho_ten, 'sdt', OLD.sdt, 'email', OLD.email,
                        'dia_chi', OLD.dia_chi, 'trang_thai', OLD.trang_thai),
            JSON_OBJECT('ho_ten', NEW.ho_ten, 'sdt', NEW.sdt, 'email', NEW.email,
                        'dia_chi', NEW.dia_chi, 'trang_thai', NEW.trang_thai),
            USER());
END$$

DROP TRIGGER IF EXISTS trg_hv_ad_audit$$
CREATE TRIGGER trg_hv_ad_audit AFTER DELETE ON hoc_vien FOR EACH ROW
BEGIN
    INSERT INTO nhat_ky_thay_doi (bang, ma_ban_ghi, hanh_dong, du_lieu_cu, nguoi_dung)
    VALUES ('hoc_vien', OLD.ma_hv, 'DELETE',
            JSON_OBJECT('ho_ten', OLD.ho_ten, 'sdt', OLD.sdt, 'email', OLD.email,
                        'trang_thai', OLD.trang_thai),
            USER());
END$$

DROP TRIGGER IF EXISTS trg_gd_au_audit$$
CREATE TRIGGER trg_gd_au_audit AFTER UPDATE ON ghi_danh FOR EACH ROW
BEGIN
    IF NEW.trang_thai_dk <> OLD.trang_thai_dk THEN
        INSERT INTO nhat_ky_thay_doi (bang, ma_ban_ghi, hanh_dong, du_lieu_cu, du_lieu_moi, nguoi_dung)
        VALUES ('ghi_danh', CONCAT(NEW.ma_hv, '/', NEW.ma_lop), 'UPDATE',
                JSON_OBJECT('trang_thai_dk', OLD.trang_thai_dk),
                JSON_OBJECT('trang_thai_dk', NEW.trang_thai_dk),
                USER());
    END IF;
END$$

DROP TRIGGER IF EXISTS trg_pt_ai_audit$$
CREATE TRIGGER trg_pt_ai_audit AFTER INSERT ON phieu_thu FOR EACH ROW
BEGIN
    INSERT INTO nhat_ky_thay_doi (bang, ma_ban_ghi, hanh_dong, du_lieu_moi, nguoi_dung)
    VALUES ('phieu_thu', NEW.ma_pt, 'INSERT',
            JSON_OBJECT('ma_dot', NEW.ma_dot, 'so_tien_thu', NEW.so_tien_thu,
                        'hinh_thuc', NEW.hinh_thuc, 'ngay_thu', NEW.ngay_thu),
            USER());
END$$

DELIMITER ;

-- =====================================================================
-- 3. STORED FUNCTION
-- =====================================================================
DROP FUNCTION IF EXISTS fn_ma_tiep_theo;
DROP FUNCTION IF EXISTS fn_tuoi;
DROP FUNCTION IF EXISTS fn_cong_no_hoc_vien;
DROP FUNCTION IF EXISTS fn_xep_loai;
DROP FUNCTION IF EXISTS fn_ty_le_chuyen_can;

DELIMITER $$

-- 3a. Sinh mã kế tiếp theo tiền tố: HV, LP, HP, DT, PT, DD, DS
--     (thay cho cách Java tự sinh "HP" + currentTimeMillis dễ trùng)
CREATE FUNCTION fn_ma_tiep_theo(p_prefix CHAR(2))
RETURNS VARCHAR(10)
READS SQL DATA
BEGIN
    DECLARE v_max INT DEFAULT 0;

    CASE p_prefix
        WHEN 'HV' THEN SELECT COALESCE(MAX(CAST(SUBSTRING(ma_hv,   3) AS UNSIGNED)), 0) INTO v_max FROM hoc_vien;
        WHEN 'LP' THEN SELECT COALESCE(MAX(CAST(SUBSTRING(ma_lop,  3) AS UNSIGNED)), 0) INTO v_max FROM lop_hoc;
        WHEN 'HP' THEN SELECT COALESCE(MAX(CAST(SUBSTRING(ma_hp,   3) AS UNSIGNED)), 0) INTO v_max FROM hoc_phi;
        WHEN 'DT' THEN SELECT COALESCE(MAX(CAST(SUBSTRING(ma_dot,  3) AS UNSIGNED)), 0) INTO v_max FROM dot_dong_hoc_phi;
        WHEN 'PT' THEN SELECT COALESCE(MAX(CAST(SUBSTRING(ma_pt,   3) AS UNSIGNED)), 0) INTO v_max FROM phieu_thu;
        WHEN 'DD' THEN SELECT COALESCE(MAX(CAST(SUBSTRING(ma_dd,   3) AS UNSIGNED)), 0) INTO v_max FROM diem_danh;
        WHEN 'DS' THEN SELECT COALESCE(MAX(CAST(SUBSTRING(ma_diem, 3) AS UNSIGNED)), 0) INTO v_max FROM diem_so;
        ELSE SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tien to ma khong hop le';
    END CASE;

    SET v_max = v_max + 1;
    RETURN CONCAT(p_prefix, IF(v_max < 100, LPAD(v_max, 2, '0'), v_max));
END$$

-- 3b. Tuổi chính xác (đã qua sinh nhật năm nay hay chưa)
CREATE FUNCTION fn_tuoi(p_ngay_sinh DATE)
RETURNS INT
DETERMINISTIC
BEGIN
    RETURN TIMESTAMPDIFF(YEAR, p_ngay_sinh, CURDATE());
END$$

-- 3c. Tổng công nợ của một học viên trên mọi lớp
CREATE FUNCTION fn_cong_no_hoc_vien(p_ma_hv VARCHAR(10))
RETURNS DECIMAL(12,2)
READS SQL DATA
BEGIN
    DECLARE v_no DECIMAL(12,2);
    SELECT COALESCE(SUM(con_no), 0) INTO v_no FROM hoc_phi WHERE ma_hv = p_ma_hv;
    RETURN v_no;
END$$

-- 3d. Xếp loại theo điểm (dùng lại thay vì lặp CASE ở nhiều view)
CREATE FUNCTION fn_xep_loai(p_diem DECIMAL(4,2))
RETURNS VARCHAR(20)
DETERMINISTIC
BEGIN
    RETURN CASE
        WHEN p_diem IS NULL THEN 'Chua du diem'
        WHEN p_diem >= 8.5  THEN 'Gioi'
        WHEN p_diem >= 7.0  THEN 'Kha'
        WHEN p_diem >= 5.0  THEN 'Trung binh'
        ELSE 'Yeu'
    END;
END$$

-- 3e. Tỷ lệ chuyên cần (%) của học viên trong một lớp
CREATE FUNCTION fn_ty_le_chuyen_can(p_ma_hv VARCHAR(10), p_ma_lop VARCHAR(10))
RETURNS DECIMAL(5,1)
READS SQL DATA
BEGIN
    DECLARE v_tong INT;
    DECLARE v_co   INT;
    SELECT COUNT(*), SUM(trang_thai IN ('Co mat','Muon'))
    INTO v_tong, v_co
    FROM diem_danh WHERE ma_hv = p_ma_hv AND ma_lop = p_ma_lop;
    RETURN IF(v_tong = 0, NULL, ROUND(100 * v_co / v_tong, 1));
END$$

DELIMITER ;

-- =====================================================================
-- 4. STORED PROCEDURE
-- =====================================================================
DROP PROCEDURE IF EXISTS sp_them_hoc_vien;
DROP PROCEDURE IF EXISTS sp_dang_ky_hoc;
DROP PROCEDURE IF EXISTS sp_thu_hoc_phi;
DROP PROCEDURE IF EXISTS sp_huy_ghi_danh;
DROP PROCEDURE IF EXISTS sp_cap_nhat_trang_thai_lop;
DROP PROCEDURE IF EXISTS sp_bao_cao_doanh_thu;
DROP PROCEDURE IF EXISTS sp_tim_kiem_hoc_vien;

DELIMITER $$

-- 4a. Thêm học viên, tự sinh mã nếu không truyền (OUT trả về mã)
CREATE PROCEDURE sp_them_hoc_vien(
    INOUT p_ma_hv    VARCHAR(10),
    IN    p_ho_ten   VARCHAR(100),
    IN    p_ngay_sinh DATE,
    IN    p_gioi_tinh VARCHAR(10),
    IN    p_dia_chi  VARCHAR(255),
    IN    p_sdt      VARCHAR(20),
    IN    p_email    VARCHAR(100))
BEGIN
    IF p_ma_hv IS NULL OR TRIM(p_ma_hv) = '' THEN
        SET p_ma_hv = fn_ma_tiep_theo('HV');
    END IF;
    INSERT INTO hoc_vien (ma_hv, ho_ten, ngay_sinh, gioi_tinh, dia_chi, sdt, email)
    VALUES (p_ma_hv, TRIM(p_ho_ten), p_ngay_sinh, p_gioi_tinh, p_dia_chi, p_sdt, LOWER(p_email));
END$$

-- 4b. ĐĂNG KÝ HỌC  =  ghi_danh + hoc_phi + chia N đợt đóng, trong MỘT giao dịch.
--     - FOR UPDATE khóa dòng lop_hoc: hai người đăng ký cùng lúc vào chỗ trống cuối
--       cùng sẽ phải xếp hàng, trigger đếm sĩ số luôn đúng (tránh race condition).
--     - Lỗi ở bất kỳ bước nào -> ROLLBACK toàn bộ (không còn ghi_danh "mồ côi").
CREATE PROCEDURE sp_dang_ky_hoc(
    IN  p_ma_hv  VARCHAR(10),
    IN  p_ma_lop VARCHAR(10),
    IN  p_so_dot TINYINT,
    OUT p_ma_hp  VARCHAR(10))
BEGIN
    DECLARE v_hoc_phi DECIMAL(12,2);
    DECLARE v_moi_dot DECIMAL(12,2);
    DECLARE v_tien    DECIMAL(12,2);
    DECLARE v_ma_dot  VARCHAR(10);
    DECLARE v_i       INT DEFAULT 1;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;              -- đẩy nguyên thông báo lỗi lên cho Java hiển thị
    END;

    IF p_so_dot IS NULL OR p_so_dot NOT BETWEEN 1 AND 12 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'So dot dong phai tu 1 den 12';
    END IF;

    START TRANSACTION;

    SELECT kh.hoc_phi_mac_dinh INTO v_hoc_phi
    FROM lop_hoc lh
    JOIN khoa_hoc kh ON kh.ma_kh = lh.ma_kh
    WHERE lh.ma_lop = p_ma_lop
    FOR UPDATE;

    IF v_hoc_phi IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lop hoc khong ton tai';
    END IF;

    -- trigger trg_gd_bi kiểm tra: trạng thái lớp, trạng thái học viên, sĩ số
    INSERT INTO ghi_danh (ma_hv, ma_lop, ngay_dang_ky, trang_thai_dk, hoc_phi)
    VALUES (p_ma_hv, p_ma_lop, CURDATE(), 'Dang ky', v_hoc_phi);

    SET p_ma_hp = fn_ma_tiep_theo('HP');
    INSERT INTO hoc_phi (ma_hp, ma_hv, ma_lop, so_tien, con_no, ngay_tao)
    VALUES (p_ma_hp, p_ma_hv, p_ma_lop, v_hoc_phi, v_hoc_phi, CURDATE());

    -- chia đều, làm tròn xuống nghìn đồng; đợt cuối gánh phần lẻ
    IF v_hoc_phi > 0 THEN
        SET v_moi_dot = FLOOR(v_hoc_phi / p_so_dot / 1000) * 1000;
        WHILE v_i <= p_so_dot DO
            SET v_tien   = IF(v_i = p_so_dot, v_hoc_phi - v_moi_dot * (p_so_dot - 1), v_moi_dot);
            SET v_ma_dot = fn_ma_tiep_theo('DT');
            INSERT INTO dot_dong_hoc_phi (ma_dot, ma_hp, so_thu_tu, so_tien_phai_dong, han_dong)
            VALUES (v_ma_dot, p_ma_hp, v_i, v_tien, DATE_ADD(CURDATE(), INTERVAL v_i - 1 MONTH));
            SET v_i = v_i + 1;
        END WHILE;
    END IF;

    COMMIT;
END$$

-- 4c. THU HỌC PHÍ  —  dùng CURSOR phân bổ số tiền vào các đợt theo thứ tự
--     (đợt cũ trước, kiểu FIFO). Một lần thu có thể sinh nhiều phiếu thu.
CREATE PROCEDURE sp_thu_hoc_phi(
    IN  p_ma_hp     VARCHAR(10),
    IN  p_so_tien   DECIMAL(12,2),
    IN  p_hinh_thuc VARCHAR(20),
    IN  p_ghi_chu   VARCHAR(255),
    OUT p_so_phieu  INT)
BEGIN
    DECLARE v_con_no   DECIMAL(12,2);
    DECLARE v_con_lai  DECIMAL(12,2);
    DECLARE v_ma_dot   VARCHAR(10);
    DECLARE v_thieu    DECIMAL(12,2);
    DECLARE v_thu      DECIMAL(12,2);
    DECLARE v_ma_pt    VARCHAR(10);
    DECLARE v_het      BOOLEAN DEFAULT FALSE;

    DECLARE cur_dot CURSOR FOR
        SELECT ma_dot, so_tien_phai_dong - so_tien_da_dong
        FROM dot_dong_hoc_phi
        WHERE ma_hp = p_ma_hp AND so_tien_da_dong < so_tien_phai_dong
        ORDER BY so_thu_tu;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_het = TRUE;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    SET p_so_phieu = 0;
    SET v_con_lai  = p_so_tien;

    START TRANSACTION;

    SELECT con_no INTO v_con_no FROM hoc_phi WHERE ma_hp = p_ma_hp FOR UPDATE;
    IF v_con_no IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Khong tim thay khoan hoc phi';
    END IF;
    SET v_het = FALSE;   -- SELECT INTO rỗng có thể đã bật cờ NOT FOUND

    IF p_so_tien IS NULL OR p_so_tien <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'So tien thu phai lon hon 0';
    END IF;
    IF p_so_tien > v_con_no THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'So tien thu vuot qua cong no con lai';
    END IF;

    OPEN cur_dot;
    doc_dot: LOOP
        FETCH cur_dot INTO v_ma_dot, v_thieu;
        IF v_het OR v_con_lai <= 0 THEN
            LEAVE doc_dot;
        END IF;

        SET v_thu   = LEAST(v_thieu, v_con_lai);
        SET v_ma_pt = fn_ma_tiep_theo('PT');
        -- trigger trg_pt_bi kiểm tra, trg_pt_ai cập nhật đợt + công nợ
        INSERT INTO phieu_thu (ma_pt, ma_dot, ngay_thu, so_tien_thu, hinh_thuc, ghi_chu)
        VALUES (v_ma_pt, v_ma_dot, CURDATE(), v_thu, p_hinh_thuc, p_ghi_chu);

        SET v_con_lai  = v_con_lai - v_thu;
        SET p_so_phieu = p_so_phieu + 1;
    END LOOP;
    CLOSE cur_dot;

    -- tiền thừa: tổng các đợt nhỏ hơn học phí (chưa chia hết đợt)
    IF v_con_lai > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cac dot da chia khong du de nhan het so tien nay';
    END IF;

    COMMIT;
END$$

-- 4d. Hủy ghi danh: chỉ cho hủy khi CHƯA đóng đồng nào (đã đóng thì phải làm hoàn phí)
CREATE PROCEDURE sp_huy_ghi_danh(IN p_ma_hv VARCHAR(10), IN p_ma_lop VARCHAR(10))
BEGIN
    DECLARE v_ma_hp VARCHAR(10);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    SELECT ma_hp INTO v_ma_hp
    FROM hoc_phi WHERE ma_hv = p_ma_hv AND ma_lop = p_ma_lop
    FOR UPDATE;

    IF EXISTS (SELECT 1
               FROM phieu_thu pt
               JOIN dot_dong_hoc_phi d ON d.ma_dot = pt.ma_dot
               WHERE d.ma_hp = v_ma_hp) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Hoc vien da dong tien, can lap phieu hoan phi truoc khi huy';
    END IF;

    DELETE FROM dot_dong_hoc_phi WHERE ma_hp = v_ma_hp;
    DELETE FROM hoc_phi          WHERE ma_hp = v_ma_hp;
    UPDATE ghi_danh SET trang_thai_dk = 'Huy'
    WHERE ma_hv = p_ma_hv AND ma_lop = p_ma_lop;

    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Khong tim thay ghi danh';
    END IF;

    COMMIT;
END$$

-- 4e. Cập nhật trạng thái lớp + ghi danh theo ngày (được EVENT gọi hằng ngày)
CREATE PROCEDURE sp_cap_nhat_trang_thai_lop()
BEGIN
    UPDATE lop_hoc
    SET trang_thai = CASE
            WHEN CURDATE() < ngay_khai_giang THEN 'Chua khai giang'
            WHEN CURDATE() > ngay_ket_thuc   THEN 'Da ket thuc'
            ELSE 'Dang hoc'
        END
    WHERE trang_thai <> 'Da huy';

    -- lớp đã khai giảng: 'Dang ky' -> 'Dang hoc'
    UPDATE ghi_danh gd
    JOIN lop_hoc lh ON lh.ma_lop = gd.ma_lop
    SET gd.trang_thai_dk = 'Dang hoc'
    WHERE gd.trang_thai_dk = 'Dang ky' AND lh.trang_thai = 'Dang hoc';

    -- lớp đã kết thúc: đang học -> hoàn thành
    UPDATE ghi_danh gd
    JOIN lop_hoc lh ON lh.ma_lop = gd.ma_lop
    SET gd.trang_thai_dk = 'Hoan thanh'
    WHERE gd.trang_thai_dk IN ('Dang ky','Dang hoc') AND lh.trang_thai = 'Da ket thuc';
END$$

-- 4f. Báo cáo doanh thu trong khoảng ngày: pivot theo hình thức thanh toán
--     + WITH ROLLUP cho dòng tổng theo khóa học và tổng toàn trung tâm.
CREATE PROCEDURE sp_bao_cao_doanh_thu(IN p_tu DATE, IN p_den DATE)
BEGIN
    SELECT
        IF(GROUPING(kh.ten_khoa_hoc) = 1, '== TONG CONG ==', kh.ten_khoa_hoc) AS khoa_hoc,
        IF(GROUPING(lh.ten_lop)      = 1, IF(GROUPING(kh.ten_khoa_hoc) = 1, '', '-- tong khoa --'),
                                          lh.ten_lop)                         AS lop,
        SUM(IF(pt.hinh_thuc = 'Tien mat',     pt.so_tien_thu, 0)) AS tien_mat,
        SUM(IF(pt.hinh_thuc = 'Chuyen khoan', pt.so_tien_thu, 0)) AS chuyen_khoan,
        SUM(IF(pt.hinh_thuc = 'The',          pt.so_tien_thu, 0)) AS the,
        SUM(IF(pt.hinh_thuc = 'Vi dien tu',   pt.so_tien_thu, 0)) AS vi_dien_tu,
        SUM(pt.so_tien_thu)                                       AS tong_thu,
        COUNT(*)                                                  AS so_phieu
    FROM phieu_thu pt
    JOIN dot_dong_hoc_phi d ON d.ma_dot  = pt.ma_dot
    JOIN hoc_phi  hp        ON hp.ma_hp  = d.ma_hp
    JOIN lop_hoc  lh        ON lh.ma_lop = hp.ma_lop
    JOIN khoa_hoc kh        ON kh.ma_kh  = lh.ma_kh
    WHERE pt.ngay_thu BETWEEN p_tu AND p_den
    GROUP BY kh.ten_khoa_hoc, lh.ten_lop WITH ROLLUP;
END$$

-- 4g. Tìm kiếm động: điều kiện + sắp xếp tùy chọn bằng PREPARE/EXECUTE.
--     Giá trị người dùng luôn đi qua tham số '?'  -> chống SQL injection;
--     tên cột sắp xếp chỉ lấy từ danh sách trắng (whitelist).
CREATE PROCEDURE sp_tim_kiem_hoc_vien(
    IN p_tu_khoa    VARCHAR(100),
    IN p_trang_thai VARCHAR(20),     -- NULL = mọi trạng thái
    IN p_sap_xep    VARCHAR(10))     -- 'ten' | 'moi' | 'no'
BEGIN
    SET @kw  = CONCAT('%', COALESCE(p_tu_khoa, ''), '%');
    SET @tt  = p_trang_thai;
    SET @sql = CONCAT(
        'SELECT hv.ma_hv, hv.ho_ten, fn_tuoi(hv.ngay_sinh) AS tuoi, hv.sdt, hv.email, hv.trang_thai, ',
        '       COALESCE(GROUP_CONCAT(DISTINCT lh.ten_lop ORDER BY lh.ten_lop SEPARATOR '', ''), ''Chua co'') AS cac_lop, ',
        '       fn_cong_no_hoc_vien(hv.ma_hv) AS cong_no ',
        'FROM hoc_vien hv ',
        'LEFT JOIN ghi_danh gd ON gd.ma_hv = hv.ma_hv AND gd.trang_thai_dk <> ''Huy'' ',
        'LEFT JOIN lop_hoc lh  ON lh.ma_lop = gd.ma_lop ',
        'WHERE (hv.ma_hv LIKE ? OR hv.ho_ten LIKE ? OR hv.sdt LIKE ?) ',
        IF(p_trang_thai IS NULL, 'AND ? IS NULL ', 'AND hv.trang_thai = ? '),
        'GROUP BY hv.ma_hv, hv.ho_ten, hv.ngay_sinh, hv.sdt, hv.email, hv.trang_thai, hv.ngay_tao ',
        'ORDER BY ',
        CASE p_sap_xep
            WHEN 'moi' THEN 'hv.ngay_tao DESC'
            WHEN 'no'  THEN 'cong_no DESC'
            ELSE            'hv.ho_ten'
        END);
    PREPARE stmt FROM @sql;
    EXECUTE stmt USING @kw, @kw, @kw, @tt;
    DEALLOCATE PREPARE stmt;
END$$

DELIMITER ;

-- =====================================================================
-- 5. VIEW NÂNG CAO
-- =====================================================================

-- 5a. Tổng quan cho màn hình Trang chủ (subquery vô hướng)
CREATE OR REPLACE VIEW v_tong_quan AS
SELECT
    (SELECT COUNT(*) FROM hoc_vien WHERE trang_thai = 'Dang hoc')                AS so_hoc_vien,
    (SELECT COUNT(*) FROM lop_hoc  WHERE trang_thai IN ('Chua khai giang','Dang hoc')) AS so_lop_mo,
    (SELECT COALESCE(SUM(so_tien_thu), 0) FROM phieu_thu)                         AS tong_da_thu,
    (SELECT COALESCE(SUM(con_no), 0) FROM hoc_phi)                                AS tong_cong_no,
    (SELECT COUNT(*) FROM v_dot_dong_hoc_phi WHERE tinh_trang_han = 'Qua han')    AS so_dot_qua_han;

-- 5b. Báo cáo theo lớp.  Mỗi số liệu gộp trong một CTE riêng rồi mới JOIN,
--     tránh lỗi "fan-out" (JOIN ghi_danh x phieu_thu x diem_so làm SUM bị nhân lên).
CREATE OR REPLACE VIEW v_bao_cao_lop AS
WITH si_so AS (
    SELECT ma_lop, COUNT(*) AS so_hv
    FROM ghi_danh WHERE trang_thai_dk IN ('Dang ky','Dang hoc','Hoan thanh')
    GROUP BY ma_lop
), tai_chinh AS (
    SELECT ma_lop, SUM(so_tien) AS phai_thu, SUM(so_tien - con_no) AS da_thu
    FROM hoc_phi GROUP BY ma_lop
), diem AS (
    SELECT ma_lop, ROUND(AVG(diem_trung_binh), 2) AS diem_tb
    FROM diem_so GROUP BY ma_lop
)
SELECT lh.ma_lop, lh.ten_lop, kh.ten_khoa_hoc, gv.ho_ten AS giao_vien, lh.trang_thai,
       COALESCE(s.so_hv, 0)                                       AS so_hoc_vien,
       lh.si_so_toi_da,
       ROUND(100 * COALESCE(s.so_hv, 0) / lh.si_so_toi_da, 1)     AS ty_le_lap_day_pct,
       COALESCE(t.phai_thu, 0)                                    AS phai_thu,
       COALESCE(t.da_thu, 0)                                      AS da_thu,
       ROUND(100 * t.da_thu / NULLIF(t.phai_thu, 0), 1)           AS ty_le_thu_pct,
       d.diem_tb
FROM lop_hoc lh
JOIN khoa_hoc  kh ON kh.ma_kh = lh.ma_kh
JOIN giao_vien gv ON gv.ma_gv = lh.ma_gv
LEFT JOIN si_so     s ON s.ma_lop = lh.ma_lop
LEFT JOIN tai_chinh t ON t.ma_lop = lh.ma_lop
LEFT JOIN diem      d ON d.ma_lop = lh.ma_lop;

-- 5c. Xếp hạng học viên trong lớp — window function
CREATE OR REPLACE VIEW v_xep_hang_lop AS
SELECT lh.ten_lop,
       hv.ma_hv,
       hv.ho_ten,
       ds.diem_trung_binh,
       fn_xep_loai(ds.diem_trung_binh)                                              AS xep_loai,
       RANK()       OVER w                                                          AS hang,
       DENSE_RANK() OVER w                                                          AS hang_lien_tuc,
       ROUND(AVG(ds.diem_trung_binh) OVER (PARTITION BY ds.ma_lop), 2)              AS tb_lop,
       ROUND(ds.diem_trung_binh - AVG(ds.diem_trung_binh) OVER (PARTITION BY ds.ma_lop), 2) AS chenh_lech_tb,
       ROUND(100 * PERCENT_RANK() OVER w, 1)                                        AS phan_vi_pct
FROM diem_so ds
JOIN hoc_vien hv ON hv.ma_hv  = ds.ma_hv
JOIN lop_hoc  lh ON lh.ma_lop = ds.ma_lop
WHERE ds.diem_trung_binh IS NOT NULL
WINDOW w AS (PARTITION BY ds.ma_lop ORDER BY ds.diem_trung_binh DESC);

-- 5d. Doanh thu theo tháng — CTE ĐỆ QUY sinh đủ dãy tháng (tháng không thu
--     tiền vẫn hiện 0), SUM() OVER lũy kế, LAG() so với tháng trước.
CREATE OR REPLACE VIEW v_doanh_thu_thang AS
WITH RECURSIVE thang AS (
    SELECT DATE_FORMAT(MIN(ngay_thu), '%Y-%m-01') AS dau_thang FROM phieu_thu
    UNION ALL
    SELECT DATE_ADD(dau_thang, INTERVAL 1 MONTH)
    FROM thang
    WHERE DATE_ADD(dau_thang, INTERVAL 1 MONTH) <= CURDATE()
), thu AS (
    SELECT DATE_FORMAT(ngay_thu, '%Y-%m-01') AS dau_thang,
           SUM(so_tien_thu) AS tong, COUNT(*) AS so_phieu
    FROM phieu_thu
    GROUP BY DATE_FORMAT(ngay_thu, '%Y-%m-01')
)
SELECT DATE_FORMAT(t.dau_thang, '%m/%Y')                              AS thang,
       COALESCE(th.so_phieu, 0)                                       AS so_phieu,
       COALESCE(th.tong, 0)                                           AS doanh_thu,
       SUM(COALESCE(th.tong, 0)) OVER (ORDER BY t.dau_thang)          AS luy_ke,
       COALESCE(th.tong, 0) - LAG(COALESCE(th.tong, 0)) OVER (ORDER BY t.dau_thang) AS so_voi_thang_truoc
FROM thang t
LEFT JOIN thu th ON th.dau_thang = t.dau_thang;

-- 5e. Học viên cần chăm sóc: nợ quá hạn HOẶC chuyên cần < 75% (CTE + UNION)
CREATE OR REPLACE VIEW v_hoc_vien_can_cham_soc AS
WITH no_qua_han AS (
    SELECT ma_hv, ten_lop, SUM(con_lai) AS so_tien, MIN(han_dong) AS han_som_nhat
    FROM v_dot_dong_hoc_phi
    WHERE tinh_trang_han = 'Qua han'
    GROUP BY ma_hv, ten_lop
), chuyen_can_thap AS (
    SELECT ma_hv, ten_lop, ty_le_chuyen_can_pct
    FROM v_chuyen_can
    WHERE ty_le_chuyen_can_pct < 75
)
SELECT hv.ma_hv, hv.ho_ten, hv.sdt, n.ten_lop,
       CAST('No qua han' AS CHAR(30)) COLLATE utf8mb4_unicode_ci AS ly_do,
       CAST(CONCAT(FORMAT(n.so_tien, 0), ' d, han ', DATE_FORMAT(n.han_som_nhat, '%d/%m/%Y'))
            AS CHAR(100)) COLLATE utf8mb4_unicode_ci AS chi_tiet
FROM no_qua_han n JOIN hoc_vien hv ON hv.ma_hv = n.ma_hv
UNION ALL
SELECT hv.ma_hv, hv.ho_ten, hv.sdt, c.ten_lop,
       CAST('Chuyen can thap' AS CHAR(30)) COLLATE utf8mb4_unicode_ci,
       CAST(CONCAT(c.ty_le_chuyen_can_pct, '%') AS CHAR(100)) COLLATE utf8mb4_unicode_ci
FROM chuyen_can_thap c JOIN hoc_vien hv ON hv.ma_hv = c.ma_hv;

-- 5f. Lịch sử đóng tiền từng học viên: số dư nợ sau mỗi phiếu (running balance)
CREATE OR REPLACE VIEW v_so_du_cong_no AS
SELECT hp.ma_hp,
       hp.ma_hv,
       lh.ten_lop,
       pt.ma_pt,
       pt.ngay_thu,
       pt.so_tien_thu,
       hp.so_tien - SUM(pt.so_tien_thu) OVER (PARTITION BY hp.ma_hp
                                              ORDER BY pt.ngay_thu, pt.ma_pt) AS con_no_sau_phieu,
       ROW_NUMBER() OVER (PARTITION BY hp.ma_hp ORDER BY pt.ngay_thu, pt.ma_pt) AS lan_dong
FROM phieu_thu pt
JOIN dot_dong_hoc_phi d ON d.ma_dot  = pt.ma_dot
JOIN hoc_phi  hp        ON hp.ma_hp  = d.ma_hp
JOIN lop_hoc  lh        ON lh.ma_lop = hp.ma_lop;

-- =====================================================================
-- 6. TRUY VẤN MINH HỌA (đưa vào báo cáo, mỗi câu kèm giải thích)
-- =====================================================================

-- 6a. PHÉP CHIA (division): học viên có mặt ở TẤT CẢ các buổi học của lớp mình.
--     "Không tồn tại buổi nào của lớp mà học viên đó không có mặt/đi muộn"
SELECT DISTINCT hv.ma_hv, hv.ho_ten, lh.ten_lop
FROM ghi_danh gd
JOIN hoc_vien hv ON hv.ma_hv  = gd.ma_hv
JOIN lop_hoc  lh ON lh.ma_lop = gd.ma_lop
WHERE NOT EXISTS (
        SELECT 1 FROM diem_danh b                     -- mọi buổi của lớp
        WHERE b.ma_lop = gd.ma_lop
          AND NOT EXISTS (
                SELECT 1 FROM diem_danh x             -- mà HV không đi
                WHERE x.ma_lop = b.ma_lop
                  AND x.ma_hv  = gd.ma_hv
                  AND x.ngay_diem_danh = b.ngay_diem_danh
                  AND x.trang_thai IN ('Co mat','Muon')))
  AND EXISTS (SELECT 1 FROM diem_danh b WHERE b.ma_lop = gd.ma_lop);

-- 6b. Truy vấn con tương quan: học viên có điểm TB cao hơn TB lớp của chính mình
SELECT hv.ho_ten, lh.ten_lop, ds.diem_trung_binh
FROM diem_so ds
JOIN hoc_vien hv ON hv.ma_hv  = ds.ma_hv
JOIN lop_hoc  lh ON lh.ma_lop = ds.ma_lop
WHERE ds.diem_trung_binh > (SELECT AVG(d2.diem_trung_binh)
                            FROM diem_so d2 WHERE d2.ma_lop = ds.ma_lop);

-- 6c. > ALL: khóa học có học phí cao hơn mọi khóa TOEIC
SELECT ten_khoa_hoc, hoc_phi_mac_dinh
FROM khoa_hoc
WHERE hoc_phi_mac_dinh > ALL (SELECT hoc_phi_mac_dinh FROM khoa_hoc
                              WHERE ten_khoa_hoc LIKE 'TOEIC%');

-- 6d. Anti-join: học viên chưa ghi danh lớp nào (LEFT JOIN ... IS NULL)
SELECT hv.ma_hv, hv.ho_ten
FROM hoc_vien hv
LEFT JOIN ghi_danh gd ON gd.ma_hv = hv.ma_hv AND gd.trang_thai_dk <> 'Huy'
WHERE gd.ma_hv IS NULL;

-- 6e. HAVING: giáo viên phụ trách từ 1 lớp trở lên đang mở, kèm tổng học viên
SELECT gv.ho_ten, COUNT(DISTINCT lh.ma_lop) AS so_lop, SUM(v.si_so_hien_tai) AS tong_hv
FROM giao_vien gv
JOIN lop_hoc lh     ON lh.ma_gv  = gv.ma_gv
JOIN v_si_so_lop v  ON v.ma_lop  = lh.ma_lop
WHERE lh.trang_thai IN ('Chua khai giang','Dang hoc')
GROUP BY gv.ma_gv, gv.ho_ten
HAVING COUNT(DISTINCT lh.ma_lop) >= 1;

-- 6f. UNION: danh bạ chung học viên + giáo viên
SELECT 'Hoc vien' AS loai, ma_hv AS ma, ho_ten, sdt, email FROM hoc_vien
UNION ALL
SELECT 'Giao vien', ma_gv, ho_ten, sdt, email FROM giao_vien
ORDER BY loai, ho_ten;

-- 6g. Top 1 học viên mỗi lớp (window + lọc ở truy vấn ngoài)
SELECT ten_lop, ho_ten, diem_trung_binh
FROM v_xep_hang_lop
WHERE hang = 1;

-- 6h. Index: so sánh kế hoạch thực thi trước/sau khi có chỉ mục.
--     idx_dot_han (han_dong, trang_thai) được dùng cho câu lọc đợt quá hạn.
EXPLAIN
SELECT ma_dot, han_dong FROM dot_dong_hoc_phi
WHERE han_dong < CURDATE() AND trang_thai <> 'Da dong';

-- =====================================================================
-- 7. EVENT — tự cập nhật trạng thái lớp lúc 00:05 mỗi ngày
--    (cần quyền SUPER/SYSTEM_VARIABLES_ADMIN để bật event_scheduler)
-- =====================================================================
SET GLOBAL event_scheduler = ON;

DROP EVENT IF EXISTS ev_cap_nhat_trang_thai_lop;
CREATE EVENT ev_cap_nhat_trang_thai_lop
    ON SCHEDULE EVERY 1 DAY
    STARTS TIMESTAMP(CURDATE() + INTERVAL 1 DAY, '00:05:00')
    COMMENT 'Cap nhat trang thai lop / ghi danh theo ngay khai giang - ket thuc'
    DO CALL sp_cap_nhat_trang_thai_lop();

-- =====================================================================
-- 8. PHÂN QUYỀN  (ROLE -> USER).  Nguyên tắc quyền tối thiểu.
--    Kế toán không có INSERT trên phieu_thu nhưng vẫn thu tiền được qua
--    sp_thu_hoc_phi (SQL SECURITY DEFINER) -> mọi khoản thu đi qua kiểm tra.
-- =====================================================================
CREATE ROLE IF NOT EXISTS 'r_giao_vu', 'r_ke_toan', 'r_giao_vien';

-- Giáo vụ: quản lý học viên, lớp, ghi danh
GRANT SELECT, INSERT, UPDATE ON trungtamngoaingu.hoc_vien  TO 'r_giao_vu';
GRANT SELECT, INSERT, UPDATE ON trungtamngoaingu.lop_hoc   TO 'r_giao_vu';
GRANT SELECT                 ON trungtamngoaingu.khoa_hoc  TO 'r_giao_vu';
GRANT SELECT                 ON trungtamngoaingu.giao_vien TO 'r_giao_vu';
GRANT SELECT                 ON trungtamngoaingu.ghi_danh  TO 'r_giao_vu';
GRANT SELECT                 ON trungtamngoaingu.v_si_so_lop   TO 'r_giao_vu';
GRANT SELECT                 ON trungtamngoaingu.v_bao_cao_lop TO 'r_giao_vu';
GRANT EXECUTE ON PROCEDURE trungtamngoaingu.sp_dang_ky_hoc       TO 'r_giao_vu';
GRANT EXECUTE ON PROCEDURE trungtamngoaingu.sp_huy_ghi_danh      TO 'r_giao_vu';
GRANT EXECUTE ON PROCEDURE trungtamngoaingu.sp_them_hoc_vien     TO 'r_giao_vu';
GRANT EXECUTE ON PROCEDURE trungtamngoaingu.sp_tim_kiem_hoc_vien TO 'r_giao_vu';

-- Kế toán: chỉ thấy vài cột liên hệ của học viên (quyền mức CỘT)
GRANT SELECT (ma_hv, ho_ten, sdt) ON trungtamngoaingu.hoc_vien TO 'r_ke_toan';
GRANT SELECT ON trungtamngoaingu.hoc_phi            TO 'r_ke_toan';
GRANT SELECT ON trungtamngoaingu.dot_dong_hoc_phi   TO 'r_ke_toan';
GRANT SELECT ON trungtamngoaingu.phieu_thu          TO 'r_ke_toan';
GRANT SELECT ON trungtamngoaingu.v_cong_no          TO 'r_ke_toan';
GRANT SELECT ON trungtamngoaingu.v_dot_dong_hoc_phi TO 'r_ke_toan';
GRANT SELECT ON trungtamngoaingu.v_doanh_thu_thang  TO 'r_ke_toan';
GRANT EXECUTE ON PROCEDURE trungtamngoaingu.sp_thu_hoc_phi       TO 'r_ke_toan';
GRANT EXECUTE ON PROCEDURE trungtamngoaingu.sp_bao_cao_doanh_thu TO 'r_ke_toan';

-- Giáo viên: điểm danh, nhập điểm — chỉ sửa được cột điểm, không sửa điểm TB
GRANT SELECT, INSERT ON trungtamngoaingu.diem_danh TO 'r_giao_vien';
GRANT SELECT, INSERT ON trungtamngoaingu.diem_so   TO 'r_giao_vien';
GRANT UPDATE (diem_giua_ky, diem_cuoi_ky, nhan_xet) ON trungtamngoaingu.diem_so TO 'r_giao_vien';
GRANT SELECT ON trungtamngoaingu.v_bang_diem    TO 'r_giao_vien';
GRANT SELECT ON trungtamngoaingu.v_xep_hang_lop TO 'r_giao_vien';
GRANT SELECT ON trungtamngoaingu.v_chuyen_can   TO 'r_giao_vien';

CREATE USER IF NOT EXISTS 'giaovu01'@'localhost'  IDENTIFIED BY 'GiaoVu@2026!';
CREATE USER IF NOT EXISTS 'ketoan01'@'localhost'  IDENTIFIED BY 'KeToan@2026!';
CREATE USER IF NOT EXISTS 'giaovien01'@'localhost' IDENTIFIED BY 'GiaoVien@2026!';
GRANT 'r_giao_vu'   TO 'giaovu01'@'localhost';
GRANT 'r_ke_toan'   TO 'ketoan01'@'localhost';
GRANT 'r_giao_vien' TO 'giaovien01'@'localhost';
SET DEFAULT ROLE ALL TO 'giaovu01'@'localhost', 'ketoan01'@'localhost', 'giaovien01'@'localhost';

-- Kiểm tra: SHOW GRANTS FOR 'ketoan01'@'localhost' USING 'r_ke_toan';

-- =====================================================================
-- 9. CHẠY THỬ
-- =====================================================================

-- Dữ liệu demo chỉ thêm MỘT lần (chạy lại file nhiều lần không bị lỗi trùng)
DROP PROCEDURE IF EXISTS sp_demo_du_lieu;
DELIMITER $$
CREATE PROCEDURE sp_demo_du_lieu()
BEGIN
    DECLARE v_ma VARCHAR(10);
    DECLARE v_hp VARCHAR(10);
    DECLARE v_so_phieu INT;

    IF NOT EXISTS (SELECT 1 FROM hoc_vien WHERE email = 'd.pham@gmail.com') THEN
        -- Thêm học viên qua procedure (mã tự sinh -> HV04)
        CALL sp_them_hoc_vien(v_ma, 'Pham Thi D', '2003-11-02', 'Nu', 'Dong Da, Ha Noi',
                              '0944444444', 'D.Pham@Gmail.com');
        -- Đăng ký IELTS-01, chia 3 đợt: 1.666.000 + 1.666.000 + 1.668.000
        CALL sp_dang_ky_hoc(v_ma, 'LP01', 3, v_hp);
        -- Đóng 3.000.000 một lần -> cursor tách thành 2 phiếu thu
        CALL sp_thu_hoc_phi(v_hp, 3000000, 'Chuyen khoan', 'Dong 2 dot dau', v_so_phieu);
        -- Sửa số điện thoại -> audit log ghi lại
        UPDATE hoc_vien SET sdt = '0944444445' WHERE ma_hv = v_ma;
    END IF;
END$$
DELIMITER ;
CALL sp_demo_du_lieu();
DROP PROCEDURE sp_demo_du_lieu;

SELECT * FROM dot_dong_hoc_phi WHERE ma_hp = (SELECT ma_hp FROM hoc_phi WHERE ma_hv = 'HV04');
SELECT * FROM v_so_du_cong_no WHERE ma_hv = 'HV04';
SELECT id, bang, ma_ban_ghi, hanh_dong, du_lieu_cu, du_lieu_moi, nguoi_dung
FROM nhat_ky_thay_doi ORDER BY id;

SELECT * FROM v_tong_quan;
SELECT * FROM v_bao_cao_lop;
SELECT * FROM v_xep_hang_lop;
SELECT * FROM v_doanh_thu_thang;
SELECT * FROM v_hoc_vien_can_cham_soc;
CALL sp_bao_cao_doanh_thu('2026-01-01', '2026-12-31');
CALL sp_tim_kiem_hoc_vien('', NULL, 'no');

-- ---------------------------------------------------------------------
-- CÁC CA KIỂM THỬ LỖI  (bỏ comment từng câu để chạy; mỗi câu phải báo lỗi)
-- ---------------------------------------------------------------------
-- CALL sp_dang_ky_hoc('HV01', 'LP01', 2, @x);        -- trùng khóa chính ghi_danh (Duplicate entry)
-- CALL sp_dang_ky_hoc('HV01', 'LP99', 2, @x);        -- Lop hoc khong ton tai
-- CALL sp_dang_ky_hoc('HV01', 'LP02', 13, @x);       -- So dot dong phai tu 1 den 12
-- CALL sp_thu_hoc_phi('HP01', 1000, 'Tien mat', NULL, @x);  -- HP01 đã đóng đủ -> vượt công nợ
-- CALL sp_huy_ghi_danh('HV01', 'LP01');              -- đã đóng tiền, không cho hủy
-- UPDATE ghi_danh SET ma_lop = 'LP02' WHERE ma_hv = 'HV01' AND ma_lop = 'LP01';  -- trg_gd_bu chặn
-- INSERT INTO phieu_thu VALUES ('PT99','DT05',CURDATE(),5000000,'Tien mat',NULL); -- vượt số còn lại của đợt
-- DELETE FROM phieu_thu WHERE ma_pt = 'PT01';        -- phiếu thu không được xóa
-- INSERT INTO hoc_vien (ma_hv,ho_ten,ngay_sinh,gioi_tinh,sdt,email)
--        VALUES ('HV05','Test 123','2000-01-01','Nam','123','x');   -- vi phạm CHECK tên/sđt/email
--
-- Kiểm thử ROLLBACK: đặt si_so_toi_da = 3 cho LP01 (đã có 3 HV) rồi đăng ký thêm 1 HV
-- -> trigger báo đủ sĩ số, procedure ROLLBACK, không còn dòng thừa nào:
-- UPDATE lop_hoc SET si_so_toi_da = 3 WHERE ma_lop = 'LP01';
-- CALL sp_dang_ky_hoc('HV03', 'LP01', 1, @x);
-- SELECT COUNT(*) FROM ghi_danh WHERE ma_hv = 'HV03' AND ma_lop = 'LP01';   -- = 0
