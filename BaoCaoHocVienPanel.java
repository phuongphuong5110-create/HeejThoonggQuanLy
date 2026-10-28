import java.awt.*;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.Vector;
import javax.swing.*;
import javax.swing.table.DefaultTableModel;

/** Báo cáo học viên theo lớp: giống giao diện cũ (chọn lớp + Xem + Xuất), dữ liệu lấy từ CSDL. */
public class BaoCaoHocVienPanel extends JPanel implements Reloadable {
    private final JComboBox<String> cbLop = new JComboBox<>();
    private final DefaultTableModel model = DbUtil.readOnlyModel();
    private final JTable table = DbUtil.table(model);

    public BaoCaoHocVienPanel() {
        JPanel page = UIStyle.page("Báo cáo học viên theo lớp", "Thống kê số lượng và danh sách học viên của từng lớp");
        JPanel body = new JPanel(new BorderLayout(0, 14));
        body.setOpaque(false);

        JPanel filter = UIStyle.card();
        filter.setLayout(new FlowLayout(FlowLayout.LEFT, 10, 5));
        JButton view = UIStyle.button("Xem báo cáo"), export = UIStyle.button("Xuất báo cáo");
        filter.add(UIStyle.label("Lớp học:"));
        filter.add(cbLop);
        filter.add(view);
        filter.add(export);
        body.add(filter, BorderLayout.NORTH);
        body.add(new JScrollPane(table), BorderLayout.CENTER);

        view.addActionListener(e -> xem());
        export.addActionListener(e -> DbUtil.exportCsv(this, table, "bao_cao_hoc_vien"));

        page.add(body, BorderLayout.CENTER);
        setLayout(new BorderLayout());
        add(page);
        reload();
    }

    @Override
    public void reload() {
        Object chon = cbLop.getSelectedItem();
        Vector<String> lop = new Vector<>();
        lop.add("Tất cả lớp");
        try (Connection c = databaseconnection.getConnection();
             PreparedStatement ps = c.prepareStatement("SELECT ten_lop FROM lop_hoc ORDER BY ten_lop");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) lop.add(rs.getString(1));
        } catch (Exception ex) {
            DbUtil.error(this, ex);
        }
        cbLop.setModel(new DefaultComboBoxModel<>(lop));
        if (chon != null) cbLop.setSelectedItem(chon);
        xem();
    }

    private void xem() {
        String lop = (String) cbLop.getSelectedItem();
        boolean tatCa = lop == null || cbLop.getSelectedIndex() == 0;
        String sql =
            "SELECT hv.ma_hv, hv.ho_ten, lh.ten_lop, gd.ngay_dang_ky, gd.trang_thai_dk, " +
            "       ds.diem_trung_binh, fn_xep_loai(ds.diem_trung_binh) AS xep_loai " +
            "FROM ghi_danh gd " +
            "JOIN hoc_vien hv ON hv.ma_hv = gd.ma_hv " +
            "JOIN lop_hoc lh  ON lh.ma_lop = gd.ma_lop " +
            "LEFT JOIN diem_so ds ON ds.ma_hv = gd.ma_hv AND ds.ma_lop = gd.ma_lop " +
            "WHERE gd.trang_thai_dk <> 'Huy' " + (tatCa ? "" : "AND lh.ten_lop = ? ") +
            "ORDER BY lh.ten_lop, hv.ma_hv";
        try {
            if (tatCa) DbUtil.query(model, sql); else DbUtil.query(model, sql, lop);
        } catch (Exception ex) {
            DbUtil.error(this, ex);
        }
    }
}
