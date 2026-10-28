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