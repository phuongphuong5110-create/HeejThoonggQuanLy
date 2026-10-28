import java.awt.*;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.Types;
import javax.swing.*;
import javax.swing.table.DefaultTableModel;

/** Thêm (qua sp_them_hoc_vien) / sửa / xóa học viên. Sửa, xóa được trigger audit ghi nhật ký. */
public class HocVienPanel extends JPanel implements Reloadable {
    private final JTextField txtMaHV = UIStyle.field(), txtHoTen = UIStyle.field(), txtNgaySinh = UIStyle.field(),
            txtDiaChi = UIStyle.field(), txtSdt = UIStyle.field(), txtEmail = UIStyle.field();
    private final JComboBox<String> cbGioiTinh = new JComboBox<>(new String[]{"Nam", "Nu", "Khac"});
    private final JComboBox<String> cbTrangThai = new JComboBox<>(new String[]{"Dang hoc", "Bao luu", "Da nghi", "Da tot nghiep"});
    private final DefaultTableModel model = DbUtil.readOnlyModel();
    private final JTable table = DbUtil.table(model);

    public HocVienPanel() {
        JPanel page = UIStyle.page("Nhập liệu học viên", "Bấm Thêm mới, nhập thông tin rồi Lưu. Để trống mã thì hệ thống tự sinh.");
        JPanel body = new JPanel(new BorderLayout(0, 14));
        body.setOpaque(false);

        JPanel form = UIStyle.card();
        form.setLayout(new BorderLayout(0, 10));
        JPanel grid = new JPanel(new GridLayout(4, 4, 10, 10));
        grid.setOpaque(false);
        txtNgaySinh.setText("2005-01-01");
        addRow(grid, "Mã học viên:", txtMaHV);
        addRow(grid, "Họ và tên:", txtHoTen);
        addRow(grid, "Ngày sinh (YYYY-MM-DD):", txtNgaySinh);
        addRow(grid, "Giới tính:", cbGioiTinh);
        addRow(grid, "Số điện thoại:", txtSdt);
        addRow(grid, "Email:", txtEmail);
        addRow(grid, "Địa chỉ:", txtDiaChi);
        addRow(grid, "Trạng thái:", cbTrangThai);
        form.add(grid, BorderLayout.CENTER);

        JPanel buttons = new JPanel(new FlowLayout(FlowLayout.RIGHT, 8, 0));
        buttons.setOpaque(false);
        JButton btnMoi = UIStyle.button("Thêm mới"), btnThem = UIStyle.button("Lưu"),
                btnSua = UIStyle.button("Cập nhật"), btnXoa = UIStyle.button("Xóa");
        buttons.add(btnMoi); buttons.add(btnThem); buttons.add(btnSua); buttons.add(btnXoa);
        form.add(buttons, BorderLayout.SOUTH);
        body.add(form, BorderLayout.NORTH);
        body.add(new JScrollPane(table), BorderLayout.CENTER);

        btnThem.addActionListener(e -> them());
        btnSua.addActionListener(e -> sua());
        btnXoa.addActionListener(e -> xoa());
        btnMoi.addActionListener(e -> {
            clearForm();
            txtHoTen.requestFocusInWindow();   // bắt đầu nhập học viên mới
        });
        table.getSelectionModel().addListSelectionListener(e -> {
            if (!e.getValueIsAdjusting()) dienForm();
        });

        page.add(body, BorderLayout.CENTER);
        setLayout(new BorderLayout());
        add(page);
        reload();
    }

    private void addRow(JPanel p, String label, JComponent c) {
        p.add(UIStyle.label(label));
        p.add(c);
    }

    @Override
    public void reload() {
        try {
            DbUtil.query(model,
                "SELECT ma_hv, ho_ten, ngay_sinh, fn_tuoi(ngay_sinh) AS tuoi, gioi_tinh, sdt, email, dia_chi, trang_thai " +
                "FROM hoc_vien ORDER BY ngay_tao DESC, ma_hv DESC");
        } catch (Exception ex) {
            DbUtil.error(this, ex);
        }
    }

    private java.sql.Date ngaySinh() {
        try {
            return java.sql.Date.valueOf(txtNgaySinh.getText().trim());
        } catch (IllegalArgumentException ex) {
            throw new IllegalArgumentException("Ngày sinh phải có dạng YYYY-MM-DD");
        }
    }

    private boolean thieuThongTin() {
        if (txtHoTen.getText().trim().isEmpty() || txtSdt.getText().trim().isEmpty()
                || txtEmail.getText().trim().isEmpty()) {
            JOptionPane.showMessageDialog(this, "Vui lòng nhập họ tên, số điện thoại và email!",
                    "Cảnh báo", JOptionPane.WARNING_MESSAGE);
            return true;
        }
        return false;
    }

    private void them() {
        if (thieuThongTin()) return;
        try (Connection c = databaseconnection.getConnection();
             CallableStatement cs = c.prepareCall("{CALL sp_them_hoc_vien(?, ?, ?, ?, ?, ?, ?)}")) {
            String ma = txtMaHV.getText().trim();
            if (ma.isEmpty()) cs.setNull(1, Types.VARCHAR); else cs.setString(1, ma);
            cs.registerOutParameter(1, Types.VARCHAR);   // tham số INOUT: nhận lại mã đã sinh
            cs.setString(2, txtHoTen.getText());
            cs.setDate(3, ngaySinh());
            cs.setString(4, (String) cbGioiTinh.getSelectedItem());
            cs.setString(5, txtDiaChi.getText().trim());
            cs.setString(6, txtSdt.getText().trim());
            cs.setString(7, txtEmail.getText().trim());
            cs.execute();
            JOptionPane.showMessageDialog(this, "Đã thêm học viên " + cs.getString(1));
            clearForm();
            reload();
        } catch (Exception ex) {
            DbUtil.error(this, ex);
        }
    }

    private void sua() {
        String ma = txtMaHV.getText().trim();
        if (ma.isEmpty()) {
            JOptionPane.showMessageDialog(this, "Chọn một học viên trong bảng để sửa.");
            return;
        }
        if (thieuThongTin()) return;
        String sql = "UPDATE hoc_vien SET ho_ten=?, ngay_sinh=?, gioi_tinh=?, dia_chi=?, sdt=?, email=?, trang_thai=? WHERE ma_hv=?";
        try (Connection c = databaseconnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, txtHoTen.getText().trim());
            ps.setDate(2, ngaySinh());
            ps.setString(3, (String) cbGioiTinh.getSelectedItem());
            ps.setString(4, txtDiaChi.getText().trim());
            ps.setString(5, txtSdt.getText().trim());
            ps.setString(6, txtEmail.getText().trim());
            ps.setString(7, (String) cbTrangThai.getSelectedItem());
            ps.setString(8, ma);
            int n = ps.executeUpdate();
            JOptionPane.showMessageDialog(this, n == 1 ? "Đã cập nhật (xem nhật ký ở màn SQL nâng cao)." : "Không tìm thấy mã " + ma);
            reload();
        } catch (Exception ex) {
            DbUtil.error(this, ex);
        }
    }

    private void xoa() {
        String ma = txtMaHV.getText().trim();
        if (ma.isEmpty()) return;
        if (JOptionPane.showConfirmDialog(this, "Xóa học viên " + ma + "?", "Xác nhận",
                JOptionPane.YES_NO_OPTION) != JOptionPane.YES_OPTION) return;
        try (Connection c = databaseconnection.getConnection();
             PreparedStatement ps = c.prepareStatement("DELETE FROM hoc_vien WHERE ma_hv=?")) {
            ps.setString(1, ma);
            ps.executeUpdate();
            clearForm();
            reload();
        } catch (Exception ex) {
            DbUtil.error(this, ex);   // học viên đã ghi danh -> lỗi khóa ngoại 1451
        }
    }

    private void dienForm() {
        int r = table.getSelectedRow();
        if (r < 0) return;
        r = table.convertRowIndexToModel(r);
        txtMaHV.setText(str(r, 0));
        txtHoTen.setText(str(r, 1));
        String ns = str(r, 2);   // dd/MM/yyyy -> yyyy-MM-dd
        if (ns.length() == 10) txtNgaySinh.setText(ns.substring(6) + "-" + ns.substring(3, 5) + "-" + ns.substring(0, 2));
        cbGioiTinh.setSelectedItem(str(r, 4));
        txtSdt.setText(str(r, 5));
        txtEmail.setText(str(r, 6));
        txtDiaChi.setText(str(r, 7));
        cbTrangThai.setSelectedItem(str(r, 8));
    }

    private String str(int r, int c) {
        Object v = model.getValueAt(r, c);
        return v == null ? "" : v.toString();
    }

    private void clearForm() {
        table.clearSelection();
        txtMaHV.setText("");
        txtHoTen.setText("");
        txtNgaySinh.setText("2005-01-01");
        txtSdt.setText("");
        txtEmail.setText("");
        txtDiaChi.setText("");
        cbGioiTinh.setSelectedIndex(0);
        cbTrangThai.setSelectedIndex(0);
    }
}
