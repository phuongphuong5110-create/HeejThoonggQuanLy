import java.awt.Component;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileOutputStream;
import java.io.OutputStreamWriter;
import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.sql.*;
import java.text.DecimalFormat;
import java.text.DecimalFormatSymbols;
import java.text.SimpleDateFormat;
import java.util.HashMap;
import java.util.Map;
import java.util.Vector;
import javax.swing.*;
import javax.swing.table.DefaultTableModel;

/** Tiện ích dùng chung: chạy truy vấn, đổ ResultSet vào JTable, định dạng tiền, xuất CSV. */
public final class DbUtil {
    private DbUtil() {}

    private static final DecimalFormat MONEY;
    static {
        DecimalFormatSymbols s = new DecimalFormatSymbols();
        s.setGroupingSeparator('.');
        s.setDecimalSeparator(',');
        MONEY = new DecimalFormat("#,##0", s);
    }
    private static final SimpleDateFormat DATE = new SimpleDateFormat("dd/MM/yyyy");

    /** Tên cột CSDL -> tiêu đề tiếng Việt hiển thị trên bảng. */
    private static final Map<String, String> HEADERS = new HashMap<>();
    static {
        String[][] h = {
            {"ma_hv", "Mã HV"}, {"ho_ten", "Họ tên"}, {"ngay_sinh", "Ngày sinh"}, {"gioi_tinh", "Giới tính"},
            {"sdt", "SĐT"}, {"email", "Email"}, {"dia_chi", "Địa chỉ"}, {"trang_thai", "Trạng thái"},
            {"ma_lop", "Mã lớp"}, {"ten_lop", "Lớp"}, {"ten_khoa_hoc", "Khóa học"}, {"giao_vien", "Giáo viên"},
            {"phong_hoc", "Phòng"}, {"si_so_hien_tai", "Sĩ số"}, {"si_so_toi_da", "Tối đa"}, {"con_trong", "Còn trống"},
            {"ngay_dang_ky", "Ngày ĐK"}, {"trang_thai_dk", "Trạng thái ĐK"}, {"hoc_phi", "Học phí"},
            {"ma_hp", "Mã HP"}, {"tong_hoc_phi", "Học phí"}, {"da_thu", "Đã thu"}, {"con_no", "Còn nợ"},
            {"ma_dot", "Mã đợt"}, {"dot_thu", "Đợt"}, {"so_tien_phai_dong", "Phải đóng"},
            {"so_tien_da_dong", "Đã đóng"}, {"con_lai", "Còn lại"}, {"han_dong", "Hạn đóng"},
            {"tinh_trang_han", "Tình trạng hạn"}, {"ma_pt", "Mã phiếu"}, {"ngay_thu", "Ngày thu"},
            {"so_tien_thu", "Số tiền thu"}, {"hinh_thuc", "Hình thức"}, {"ghi_chu", "Ghi chú"},
            {"con_no_sau_phieu", "Nợ sau phiếu"}, {"lan_dong", "Lần đóng"},
            {"diem_giua_ky", "Giữa kỳ"}, {"diem_cuoi_ky", "Cuối kỳ"}, {"diem_trung_binh", "Điểm TB"},
            {"xep_loai", "Xếp loại"}, {"hang", "Hạng"}, {"hang_lien_tuc", "Hạng (dense)"}, {"tb_lop", "TB lớp"},
            {"chenh_lech_tb", "Chênh TB"}, {"phan_vi_pct", "Phân vị %"}, {"so_hoc_vien", "Số HV"},
            {"ty_le_lap_day_pct", "Lấp đầy %"}, {"phai_thu", "Phải thu"}, {"ty_le_thu_pct", "Đã thu %"},
            {"diem_tb", "Điểm TB"}, {"thang", "Tháng"}, {"so_phieu", "Số phiếu"}, {"doanh_thu", "Doanh thu"},
            {"luy_ke", "Lũy kế"}, {"so_voi_thang_truoc", "So tháng trước"}, {"ly_do", "Lý do"},
            {"chi_tiet", "Chi tiết"}, {"tuoi", "Tuổi"}, {"cac_lop", "Các lớp"}, {"cong_no", "Công nợ"},
            {"chuyen_can_pct", "Chuyên cần %"}, {"khoa_hoc", "Khóa học"}, {"lop", "Lớp"},
            {"tien_mat", "Tiền mặt"}, {"chuyen_khoan", "Chuyển khoản"}, {"the", "Thẻ"},
            {"vi_dien_tu", "Ví điện tử"}, {"tong_thu", "Tổng thu"}
        };
        for (String[] p : h) HEADERS.put(p[0], p[1]);
    }

    public static DefaultTableModel readOnlyModel() {
        return new DefaultTableModel() {
            @Override public boolean isCellEditable(int r, int c) { return false; }
        };
    }

    public static JTable table(DefaultTableModel model) {
        JTable t = new JTable(model);
        t.setRowHeight(28);
        t.setAutoCreateRowSorter(true);
        t.getTableHeader().setReorderingAllowed(false);
        return t;
    }

    private static void bind(PreparedStatement ps, Object... params) throws SQLException {
        for (int i = 0; i < params.length; i++) ps.setObject(i + 1, params[i]);
    }

    /** Chạy SELECT / CALL có tham số và đổ toàn bộ kết quả (kể cả tên cột) vào model. */
    public static void query(DefaultTableModel model, String sql, Object... params) throws SQLException {
        try (Connection c = databaseconnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            bind(ps, params);
            try (ResultSet rs = ps.executeQuery()) {
                fill(model, rs);
            }
        }
    }

    public static void fill(DefaultTableModel model, ResultSet rs) throws SQLException {
        ResultSetMetaData md = rs.getMetaData();
        int n = md.getColumnCount();
        Vector<String> cols = new Vector<>();
        for (int i = 1; i <= n; i++) cols.add(header(md.getColumnLabel(i)));
        Vector<Vector<Object>> rows = new Vector<>();
        while (rs.next()) {
            Vector<Object> row = new Vector<>();
            for (int i = 1; i <= n; i++) row.add(format(rs.getObject(i)));
            rows.add(row);
        }
        model.setDataVector(rows, cols);
    }

    /** Lấy một giá trị đơn (COUNT, SUM...). */
    public static Object scalar(String sql, Object... params) throws SQLException {
        try (Connection c = databaseconnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            bind(ps, params);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getObject(1) : null;
            }
        }
    }

    public static String header(String col) {
        String h = HEADERS.get(col);
        return h != null ? h : col;
    }

    public static Object format(Object v) {
        if (v == null) return "";
        if (v instanceof BigDecimal) {
            BigDecimal b = (BigDecimal) v;
            // số tiền (>= 1.000) hiển thị dạng 1.500.000; điểm, % giữ nguyên
            if (b.abs().compareTo(new BigDecimal(1000)) >= 0) return MONEY.format(b);
            return b.stripTrailingZeros().toPlainString();
        }
        if (v instanceof java.sql.Date) return DATE.format((java.util.Date) v);
        if (v instanceof java.time.LocalDate) return DATE.format(java.sql.Date.valueOf((java.time.LocalDate) v));
        return v;
    }

    public static String money(Object v) {
        if (v == null) return "0đ";
        return MONEY.format(new BigDecimal(v.toString())) + "đ";
    }

    /** Hiển thị lỗi: thông báo từ SIGNAL trong trigger/procedure được đưa thẳng lên giao diện. */
    public static void error(Component parent, Exception ex) {
        String msg = ex.getMessage();
        if (ex instanceof SQLException && ((SQLException) ex).getErrorCode() == 1451) {
            msg = "Không thể xóa: dữ liệu đang được tham chiếu ở bảng khác (khóa ngoại).";
        }
        JOptionPane.showMessageDialog(parent, msg, "Lỗi CSDL", JOptionPane.ERROR_MESSAGE);
    }

    /** Xuất bảng ra CSV (UTF-8 có BOM để Excel đọc đúng tiếng Việt). */
    public static void exportCsv(Component parent, JTable table, String defaultName) {
        JFileChooser fc = new JFileChooser();
        fc.setSelectedFile(new File(defaultName + ".csv"));
        if (fc.showSaveDialog(parent) != JFileChooser.APPROVE_OPTION) return;
        try (BufferedWriter w = new BufferedWriter(new OutputStreamWriter(
                new FileOutputStream(fc.getSelectedFile()), StandardCharsets.UTF_8))) {
            w.write('﻿');
            for (int c = 0; c < table.getColumnCount(); c++) {
                if (c > 0) w.write(',');
                w.write(csv(table.getColumnName(c)));
            }
            w.newLine();
            for (int r = 0; r < table.getRowCount(); r++) {
                for (int c = 0; c < table.getColumnCount(); c++) {
                    if (c > 0) w.write(',');
                    Object v = table.getValueAt(r, c);
                    w.write(csv(v == null ? "" : v.toString()));
                }
                w.newLine();
            }
            JOptionPane.showMessageDialog(parent, "Đã xuất " + table.getRowCount() + " dòng ra " + fc.getSelectedFile().getName());
        } catch (Exception ex) {
            error(parent, ex);
        }
    }

    private static String csv(String s) {
        return "\"" + s.replace("\"", "\"\"") + "\"";
    }
}
