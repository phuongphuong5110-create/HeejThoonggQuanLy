QUẢN LÝ TRUNG TÂM NGOẠI NGỮ — JAVA SWING + MySQL 8

=== CÀI ĐẶT CSDL (chạy theo thứ tự) ===
CÁCH NHANH NHẤT: chỉ chạy setup_all.sql. Chạy lại bao nhiêu lần cũng KHÔNG mất dữ liệu đã nhập.
Muốn xóa sạch về dữ liệu mẫu: chạy reset_database.sql rồi advanced.sql.

1. database.sql  : tạo bảng, ràng buộc, chỉ mục, trigger, view, dữ liệu mẫu
2. advanced.sql  : phần SQL nâng cao (procedure, function, cursor, transaction,
                   CTE, window function, audit log, event, phân quyền)
   mysql -u root -p < database.sql
   mysql -u root -p < advanced.sql
   (MySQL Workbench: mở từng file, bấm biểu tượng tia sét để chạy cả file)

=== CHẠY CHƯƠNG TRÌNH ===
- Thêm mysql-connector-j-8.x.jar vào Project Libraries (IntelliJ: File > Project Structure > Libraries)
- Sửa mật khẩu MySQL trong databaseconnection.java
- Chạy MainFrame.java
  Dòng lệnh:  javac -encoding UTF-8 *.java
              java -cp ".;mysql-connector-j-8.4.0.jar" MainFrame      (Windows; Linux/macOS dùng ':')

=== CÁC FILE ===
- MainFrame.java            : cửa sổ chính, menu; mở màn nào thì tải lại dữ liệu màn đó
- TrangChuPanel.java        : số liệu tổng quan (v_tong_quan), HV cần chăm sóc
- HocVienPanel.java         : thêm (sp_them_hoc_vien, tự sinh mã) / sửa / xóa học viên
- DangKyPanel.java          : đăng ký (sp_dang_ky_hoc: transaction + chia đợt), hủy (sp_huy_ghi_danh)
- ThuHocPhiPanel.java       : thu tiền (sp_thu_hoc_phi: cursor phân bổ vào các đợt)
- TimKiemHocVienPanel.java  : tìm kiếm (sp_tim_kiem_hoc_vien: SQL động PREPARE/EXECUTE)
- TimKiemLopPanel.java      : tra cứu lớp (v_si_so_lop)
- BaoCaoHocVienPanel.java   : báo cáo theo lớp (v_bao_cao_lop, RANK() OVER), xuất CSV
- BaoCaoHocPhiPanel.java    : công nợ, doanh thu tháng (CTE đệ quy), ROLLUP, xuất CSV
- DbUtil.java               : tiện ích truy vấn, định dạng tiền, xuất CSV
- UIStyle.java, Reloadable.java, databaseconnection.java

=== TÀI KHOẢN PHÂN QUYỀN (tạo bởi advanced.sql) ===
- giaovu01 / GiaoVu@2026!     : quản lý học viên, lớp, ghi danh
- ketoan01 / KeToan@2026!     : chỉ xem 3 cột của hoc_vien; thu tiền CHỈ qua sp_thu_hoc_phi
- giaovien01 / GiaoVien@2026! : điểm danh, chỉ được sửa cột điểm
