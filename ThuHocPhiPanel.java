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
 * Thu học phí qua sp_thu_hoc_phi: procedure dùng CURSOR duyệt các đợt chưa đóng
 * theo thứ tự và tự tách số tiền thành nhiều phiếu thu.
 */
public class ThuHocPhiPanel extends JPanel implements Reloadable {
    private final JComboBox<DangKyPanel.Item> cbKhoan = new JComboBox<>();
    private final JTextField txtSoTien = UIStyle.field();
    private final JComboBox<String> cbHinhThuc = new JComboBox<>(new String[]{"Tien mat", "Chuyen khoan", "The", "Vi dien tu"});
    private final JTextField txtGhiChu = UIStyle.field();
    private final DefaultTableModel mDot = DbUtil.readOnlyModel();
    private final DefaultTableModel mLichSu = DbUtil.readOnlyModel();

    public ThuHocPhiPanel() {
        JPanel page = UIStyle.page("Thu học phí", "Số tiền được phân bổ tự động vào các đợt cũ trước (stored procedure + cursor)");
        JPanel body = new JPanel(new BorderLayout(0, 14));
        body.setOpaque(false);

        JPanel form = UIStyle.card();
        form.setLayout(new BorderLayout(0, 10));
        JPanel grid = new JPanel(new GridLayout(2, 4, 10, 10));
        grid.setOpaque(false);
        grid.add(UIStyle.label("Khoản còn nợ:"));  grid.add(cbKhoan);
        grid.add(UIStyle.label("Số tiền thu:"));   grid.add(txtSoTien);
        grid.add(UIStyle.label("Hình thức:"));     grid.add(cbHinhThuc);
        grid.add(UIStyle.label("Ghi chú:"));       grid.add(txtGhiChu);
        form.add(grid, BorderLayout.CENTER);
        JPanel buttons = new JPanel(new FlowLayout(FlowLayout.RIGHT, 8, 0));
        buttons.setOpaque(false);
        JButton btnThu = UIStyle.button("Lập phiếu thu");
        buttons.add(btnThu);
        form.add(buttons, BorderLayout.SOUTH);
        body.add(form, BorderLayout.NORTH);

        JSplitPane split = new JSplitPane(JSplitPane.VERTICAL_SPLIT,
                titled("Các đợt đóng của khoản này", mDot),
                titled("Lịch sử phiếu thu và số nợ còn lại sau mỗi lần đóng", mLichSu));
        split.setResizeWeight(0.5);
        split.setBorder(null);
        body.add(split, BorderLayout.CENTER);

        cbKhoan.addActionListener(e -> taiChiTiet());
        btnThu.addActionListener(e -> thu());

        page.add(body, BorderLayout.CENTER);
        setLayout(new BorderLayout());
        add(page);
        reload();
    }

    private JPanel titled(String title, DefaultTableModel m) {
        JPanel p = new JPanel(new BorderLayout(0, 4));
        p.setOpaque(false);
        p.add(UIStyle.label(title), BorderLayout.NORTH);
        p.add(new JScrollPane(DbUtil.table(m)), BorderLayout.CENTER);
        return p;
    }

    @Override
    public void reload() {
        Vector<DangKyPanel.Item> items = new Vector<>();
        try (Connection c = databaseconnection.getConnection();
             PreparedStatement ps = c.prepareStatement(
                     "SELECT ma_hp, ho_ten, ten_lop, con_no FROM v_cong_no WHERE con_no > 0 ORDER BY ho_ten");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                items.add(new DangKyPanel.Item(rs.getString("ma_hp"),
                        rs.getString("ma_hp") + " - " + rs.getString("ho_ten") + " - " + rs.getString("ten_lop")
                                + " (nợ " + DbUtil.money(rs.getBigDecimal("con_no")) + ")",
                        rs.getBigDecimal("con_no")));
            }
        } catch (Exception ex) {
            DbUtil.error(this, ex);
        }
        cbKhoan.setModel(new DefaultComboBoxModel<>(items));
        taiChiTiet();
    }

    private void taiChiTiet() {
        DangKyPanel.Item k = (DangKyPanel.Item) cbKhoan.getSelectedItem();
        String maHp = k == null ? "" : k.key;
        if (k != null) txtSoTien.setText(k.hocPhi.toBigInteger().toString());
        try {
            DbUtil.query(mDot,
                "SELECT dot_thu, so_tien_phai_dong, so_tien_da_dong, con_lai, han_dong, trang_thai, tinh_trang_han " +
                "FROM v_dot_dong_hoc_phi WHERE ma_hp = ? ORDER BY dot_thu", maHp);
            DbUtil.query(mLichSu,
                "SELECT lan_dong, ma_pt, ngay_thu, so_tien_thu, con_no_sau_phieu " +
                "FROM v_so_du_cong_no WHERE ma_hp = ? ORDER BY lan_dong", maHp);
        } catch (Exception ex) {
            DbUtil.error(this, ex);
        }
    }

    private void thu() {
        DangKyPanel.Item k = (DangKyPanel.Item) cbKhoan.getSelectedItem();
        if (k == null) return;
        BigDecimal soTien;
        try {
            soTien = new BigDecimal(txtSoTien.getText().trim().replace(".", "").replace(",", ""));
        } catch (NumberFormatException ex) {
            JOptionPane.showMessageDialog(this, "Số tiền không hợp lệ");
            return;
        }
        try (Connection c = databaseconnection.getConnection();
             CallableStatement cs = c.prepareCall("{CALL sp_thu_hoc_phi(?, ?, ?, ?, ?)}")) {
            cs.setString(1, k.key);
            cs.setBigDecimal(2, soTien);
            cs.setString(3, (String) cbHinhThuc.getSelectedItem());
            cs.setString(4, txtGhiChu.getText().trim());
            cs.registerOutParameter(5, Types.INTEGER);
            cs.execute();
            JOptionPane.showMessageDialog(this, "Đã thu " + DbUtil.money(soTien) + ", lập " + cs.getInt(5) + " phiếu thu.");
            txtGhiChu.setText("");
            String giuLai = k.key;
            reload();
            for (int i = 0; i < cbKhoan.getItemCount(); i++) {
                if (cbKhoan.getItemAt(i).key.equals(giuLai)) cbKhoan.setSelectedIndex(i);
            }
        } catch (Exception ex) {
            DbUtil.error(this, ex);
        }
    }
}
