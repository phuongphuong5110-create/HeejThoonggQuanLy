import java.awt.*;
import java.awt.event.KeyAdapter;
import java.awt.event.KeyEvent;
import javax.swing.*;
import javax.swing.table.DefaultTableModel;

/**
 * Tìm học viên qua sp_tim_kiem_hoc_vien (SQL động PREPARE/EXECUTE).
 * Mỗi học viên một dòng, các lớp gộp bằng GROUP_CONCAT (bản cũ dùng LEFT JOIN
 * nên học viên học 2 lớp bị lặp 2 dòng).
 */
public class TimKiemHocVienPanel extends JPanel implements Reloadable {
    private final JTextField txtSearch = new JTextField(24);
    private final JComboBox<String> cbTrangThai = new JComboBox<>(new String[]{"Tất cả", "Dang hoc", "Bao luu", "Da nghi", "Da tot nghiep"});
    private final JComboBox<String> cbSapXep = new JComboBox<>(new String[]{"Theo tên", "Mới nhất", "Công nợ cao"});
    private final DefaultTableModel model = DbUtil.readOnlyModel();

    public TimKiemHocVienPanel() {
        JPanel page = UIStyle.page("Tìm học viên", "Tìm theo mã, họ tên hoặc số điện thoại; lọc trạng thái, sắp xếp theo công nợ");
        JPanel body = new JPanel(new BorderLayout(0, 14));
        body.setOpaque(false);

        JPanel filter = UIStyle.card();
        filter.setLayout(new FlowLayout(FlowLayout.LEFT, 10, 0));
        filter.add(UIStyle.label("Từ khóa:"));    filter.add(txtSearch);
        filter.add(UIStyle.label("Trạng thái:")); filter.add(cbTrangThai);
        filter.add(UIStyle.label("Sắp xếp:"));    filter.add(cbSapXep);
        body.add(filter, BorderLayout.NORTH);
        body.add(new JScrollPane(DbUtil.table(model)), BorderLayout.CENTER);

        txtSearch.addKeyListener(new KeyAdapter() {
            @Override public void keyReleased(KeyEvent e) { reload(); }
        });
        cbTrangThai.addActionListener(e -> reload());
        cbSapXep.addActionListener(e -> reload());

        page.add(body, BorderLayout.CENTER);
        setLayout(new BorderLayout());
        add(page);
        reload();
    }

    @Override
    public void reload() {
        String tt = cbTrangThai.getSelectedIndex() == 0 ? null : (String) cbTrangThai.getSelectedItem();
        String[] sort = {"ten", "moi", "no"};
        try {
            DbUtil.query(model, "CALL sp_tim_kiem_hoc_vien(?, ?, ?)",
                    txtSearch.getText().trim(), tt, sort[cbSapXep.getSelectedIndex()]);
        } catch (Exception ex) {
            DbUtil.error(this, ex);
        }
    }
}
