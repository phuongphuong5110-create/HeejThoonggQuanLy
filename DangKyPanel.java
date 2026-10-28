import java.awt.*;
import java.math.BigDecimal;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Types;
import java.util.Vector;
import javax.swing.*;
import javax.swing.table.DefaultTableModel;

/**
 * Đăng ký học: gọi MỘT stored procedure sp_dang_ky_hoc.
 * Procedure làm trong một transaction: ghi_danh + hoc_phi + chia đợt đóng,
 * khóa dòng lớp (FOR UPDATE) để không vượt sĩ số khi nhiều người đăng ký cùng lúc.
 */
public class DangKyPanel extends JPanel implements Reloadable {
    private final JComboBox<Item> cbHocVien = new JComboBox<>();
    private final JComboBox<Item> cbLopHoc = new JComboBox<>();
    private final JSpinner spSoDot = new JSpinner(new SpinnerNumberModel(2, 1, 12, 1));
    private final JLabel lblHocPhi = UIStyle.label("");
    private final DefaultTableModel model = DbUtil.readOnlyModel();
    private final JTable table = DbUtil.table(model);

    public DangKyPanel() {
        JPanel page = UIStyle.page("Nhập liệu đăng ký", "Ghi danh học viên vào lớp và tự chia học phí thành nhiều đợt");
        JPanel body = new JPanel(new BorderLayout(0, 14));
        body.setOpaque(false);

        JPanel form = UIStyle.card();
        form.setLayout(new BorderLayout(0, 10));
        JPanel grid = new JPanel(new GridLayout(4, 2, 10, 10));
        grid.setOpaque(false);
        JButton btnHvMoi = UIStyle.button("+ Học viên mới");
        JPanel hvRow = new JPanel(new BorderLayout(6, 0));
        hvRow.setOpaque(false);
        hvRow.add(cbHocVien, BorderLayout.CENTER);
        hvRow.add(btnHvMoi, BorderLayout.EAST);
        grid.add(UIStyle.label("Học viên (đang học):")); grid.add(hvRow);
        grid.add(UIStyle.label("Lớp học (còn nhận):"));  grid.add(cbLopHoc);
        grid.add(UIStyle.label("Số đợt đóng học phí:")); grid.add(spSoDot);
        grid.add(UIStyle.label("Học phí:"));              grid.add(lblHocPhi);
        form.add(grid, BorderLayout.CENTER);

        JPanel buttons = new JPanel(new FlowLayout(FlowLayout.RIGHT, 8, 0));
        buttons.setOpaque(false);
        JButton btnMoi = UIStyle.button("Thêm mới");
        JButton btnDangKy = UIStyle.button("Đăng ký ghi danh");
        JButton btnHuy = UIStyle.button("Hủy ghi danh đã chọn");
        buttons.add(btnMoi); buttons.add(btnDangKy); buttons.add(btnHuy);
        form.add(buttons, BorderLayout.SOUTH);

        body.add(form, BorderLayout.NORTH);
        body.add(new JScrollPane(table), BorderLayout.CENTER);

        cbLopHoc.addActionListener(e -> capNhatHocPhi());
        spSoDot.addChangeListener(e -> capNhatHocPhi());
        btnDangKy.addActionListener(e -> dangKy());
        btnHuy.addActionListener(e -> huy());
        btnMoi.addActionListener(e -> themMoi());
        btnHvMoi.addActionListener(e -> nhapNhanhHocVien());

        page.add(body, BorderLayout.CENTER);
        setLayout(new BorderLayout());
        add(page);
        reload();
    }

    @Override
    public void reload() {
        try (Connection c = databaseconnection.getConnection()) {
            Vector<Item> hv = new Vector<>();
            try (PreparedStatement ps = c.prepareStatement(
                    "SELECT ma_hv, ho_ten FROM hoc_vien WHERE trang_thai = 'Dang hoc' ORDER BY ho_ten");
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) hv.add(new Item(rs.getString(1), rs.getString(2) + " (" + rs.getString(1) + ")", null));
            }
            cbHocVien.setModel(new DefaultComboBoxModel<>(hv));

            // lấy từ view sĩ số: chỉ lớp còn chỗ, hiển thị số chỗ trống
            Vector<Item> lop = new Vector<>();
            try (PreparedStatement ps = c.prepareStatement(
                    "SELECT v.ma_lop, v.ten_lop, v.ten_khoa_hoc, v.con_trong, kh.hoc_phi_mac_dinh " +
                    "FROM v_si_so_lop v JOIN lop_hoc lh ON lh.ma_lop = v.ma_lop " +
                    "JOIN khoa_hoc kh ON kh.ma_kh = lh.ma_kh " +
                    "WHERE v.trang_thai IN ('Chua khai giang','Dang hoc') AND v.con_trong > 0 ORDER BY v.ten_lop");
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    lop.add(new Item(rs.getString("ma_lop"),
                            rs.getString("ten_lop") + " - " + rs.getString("ten_khoa_hoc")
                                    + "  [còn " + rs.getInt("con_trong") + " chỗ]",
                            rs.getBigDecimal("hoc_phi_mac_dinh")));
                }
            }
            cbLopHoc.setModel(new DefaultComboBoxModel<>(lop));
            capNhatHocPhi();

            DbUtil.query(model,
                "SELECT gd.ma_hv, hv.ho_ten, gd.ma_lop, lh.ten_lop, gd.ngay_dang_ky, gd.trang_thai_dk, " +
                "       gd.hoc_phi, hp.ma_hp, hp.con_no, COUNT(d.ma_dot) AS so_dot " +
                "FROM ghi_danh gd " +
                "JOIN hoc_vien hv ON hv.ma_hv = gd.ma_hv " +
                "JOIN lop_hoc lh  ON lh.ma_lop = gd.ma_lop " +
                "LEFT JOIN hoc_phi hp ON hp.ma_hv = gd.ma_hv AND hp.ma_lop = gd.ma_lop " +
                "LEFT JOIN dot_dong_hoc_phi d ON d.ma_hp = hp.ma_hp " +
                "GROUP BY gd.ma_hv, hv.ho_ten, gd.ma_lop, lh.ten_lop, gd.ngay_dang_ky, gd.trang_thai_dk, " +
                "         gd.hoc_phi, hp.ma_hp, hp.con_no " +
                "ORDER BY gd.ngay_dang_ky DESC, gd.ma_hv");
        } catch (Exception ex) {
            DbUtil.error(this, ex);
        }
    }

    private void capNhatHocPhi() {
        Item lop = (Item) cbLopHoc.getSelectedItem();
        if (lop == null || lop.hocPhi == null) {
            lblHocPhi.setText("");
            return;
        }
        int soDot = (Integer) spSoDot.getValue();
        BigDecimal moiDot = lop.hocPhi.divide(BigDecimal.valueOf(soDot), 0, java.math.RoundingMode.DOWN)
                .divide(BigDecimal.valueOf(1000), 0, java.math.RoundingMode.DOWN).multiply(BigDecimal.valueOf(1000));
        lblHocPhi.setText(DbUtil.money(lop.hocPhi) + (soDot > 1 ? "  —  mỗi đợt ≈ " + DbUtil.money(moiDot) : ""));
    }

    private void dangKy() {
        Item hv = (Item) cbHocVien.getSelectedItem();
        Item lop = (Item) cbLopHoc.getSelectedItem();
        if (hv == null || lop == null) {
            JOptionPane.showMessageDialog(this, "Vui lòng chọn học viên và lớp học!", "Thông báo", JOptionPane.WARNING_MESSAGE);
            return;
        }
        try (Connection c = databaseconnection.getConnection();
             CallableStatement cs = c.prepareCall("{CALL sp_dang_ky_hoc(?, ?, ?, ?)}")) {
            cs.setString(1, hv.key);
            cs.setString(2, lop.key);
            cs.setInt(3, (Integer) spSoDot.getValue());
            cs.registerOutParameter(4, Types.VARCHAR);
            cs.execute();
            JOptionPane.showMessageDialog(this, "Đăng ký thành công! Mã học phí: " + cs.getString(4));
            reload();
        } catch (Exception ex) {
            DbUtil.error(this, ex);   // thông báo từ trigger: đủ sĩ số, HV bảo lưu, trùng ghi danh...
        }
    }

    private void huy() {
        int r = table.getSelectedRow();
        if (r < 0) {
            JOptionPane.showMessageDialog(this, "Chọn một dòng ghi danh trong bảng.");
            return;
        }
        r = table.convertRowIndexToModel(r);
        String maHv = model.getValueAt(r, 0).toString(), maLop = model.getValueAt(r, 2).toString();
        if (JOptionPane.showConfirmDialog(this, "Hủy ghi danh " + maHv + " khỏi lớp " + maLop + "?",
                "Xác nhận", JOptionPane.YES_NO_OPTION) != JOptionPane.YES_OPTION) return;
        try (Connection c = databaseconnection.getConnection();
             CallableStatement cs = c.prepareCall("{CALL sp_huy_ghi_danh(?, ?)}")) {
            cs.setString(1, maHv);
            cs.setString(2, maLop);
            cs.execute();
            reload();
        } catch (Exception ex) {
            DbUtil.error(this, ex);
        }
    }

    /** Đưa form về trạng thái ban đầu để nhập một đăng ký mới. */
    private void themMoi() {
        reload();
        table.clearSelection();
        if (cbHocVien.getItemCount() > 0) cbHocVien.setSelectedIndex(0);
        if (cbLopHoc.getItemCount() > 0) cbLopHoc.setSelectedIndex(0);
        spSoDot.setValue(1);
        cbHocVien.requestFocusInWindow();
    }

    /** Hộp thoại nhập nhanh học viên mới (gọi sp_them_hoc_vien), lưu xong chọn sẵn học viên đó. */
    private void nhapNhanhHocVien() {
        JTextField ten = new JTextField(), ngaySinh = new JTextField("2005-01-01"),
                sdt = new JTextField(), email = new JTextField(), diaChi = new JTextField();
        JComboBox<String> gioiTinh = new JComboBox<>(new String[]{"Nam", "Nu", "Khac"});
        JPanel p = new JPanel(new GridLayout(6, 2, 8, 8));
        p.add(new JLabel("Họ và tên:"));               p.add(ten);
        p.add(new JLabel("Ngày sinh (YYYY-MM-DD):"));  p.add(ngaySinh);
        p.add(new JLabel("Giới tính:"));               p.add(gioiTinh);
        p.add(new JLabel("Số điện thoại:"));           p.add(sdt);
        p.add(new JLabel("Email:"));                   p.add(email);
        p.add(new JLabel("Địa chỉ:"));                 p.add(diaChi);
        if (JOptionPane.showConfirmDialog(this, p, "Thêm học viên mới",
                JOptionPane.OK_CANCEL_OPTION, JOptionPane.PLAIN_MESSAGE) != JOptionPane.OK_OPTION) return;
        try (Connection c = databaseconnection.getConnection();
             CallableStatement cs = c.prepareCall("{CALL sp_them_hoc_vien(?, ?, ?, ?, ?, ?, ?)}")) {
            cs.setNull(1, Types.VARCHAR);
            cs.registerOutParameter(1, Types.VARCHAR);
            cs.setString(2, ten.getText().trim());
            cs.setDate(3, java.sql.Date.valueOf(ngaySinh.getText().trim()));
            cs.setString(4, (String) gioiTinh.getSelectedItem());
            cs.setString(5, diaChi.getText().trim());
            cs.setString(6, sdt.getText().trim());
            cs.setString(7, email.getText().trim());
            cs.execute();
            String ma = cs.getString(1);
            reload();
            for (int i = 0; i < cbHocVien.getItemCount(); i++)
                if (cbHocVien.getItemAt(i).key.equals(ma)) cbHocVien.setSelectedIndex(i);
            JOptionPane.showMessageDialog(this, "Đã thêm học viên " + ma + ". Chọn lớp rồi bấm Đăng ký.");
        } catch (IllegalArgumentException ex) {
            JOptionPane.showMessageDialog(this, "Ngày sinh phải có dạng YYYY-MM-DD");
        } catch (Exception ex) {
            DbUtil.error(this, ex);
        }
    }

    static class Item {
        final String key, text;
        final BigDecimal hocPhi;
        Item(String key, String text, BigDecimal hocPhi) { this.key = key; this.text = text; this.hocPhi = hocPhi; }
        @Override public String toString() { return text; }
    }
}
