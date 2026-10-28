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
