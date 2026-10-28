import java.awt.*;
import java.awt.event.KeyAdapter;
import java.awt.event.KeyEvent;
import javax.swing.*;
import javax.swing.table.DefaultTableModel;

/** Tra cứu lớp từ view v_si_so_lop (sĩ số tính bằng LEFT JOIN + GROUP BY). */
public class TimKiemLopPanel extends JPanel implements Reloadable {
    private final JTextField txtSearch = new JTextField(30);
    private final JCheckBox chkConCho = new JCheckBox("Chỉ lớp còn chỗ");
    private final DefaultTableModel model = DbUtil.readOnlyModel();

    public TimKiemLopPanel() {
        JPanel page = UIStyle.page("Tìm lớp học", "Tra cứu lớp theo mã lớp, tên lớp, khóa học hoặc giáo viên");
        JPanel body = new JPanel(new BorderLayout(0, 14));
        body.setOpaque(false);

        JPanel filter = UIStyle.card();
        filter.setLayout(new FlowLayout(FlowLayout.LEFT, 10, 0));
        chkConCho.setOpaque(false);
        filter.add(UIStyle.label("Từ khóa:"));
        filter.add(txtSearch);
        filter.add(chkConCho);
        body.add(filter, BorderLayout.NORTH);
        body.add(new JScrollPane(DbUtil.table(model)), BorderLayout.CENTER);

        txtSearch.addKeyListener(new KeyAdapter() {
            @Override public void keyReleased(KeyEvent e) { reload(); }
        });
        chkConCho.addActionListener(e -> reload());

        page.add(body, BorderLayout.CENTER);
        setLayout(new BorderLayout());
        add(page);
        reload();
    }

    @Override
    public void reload() {
        String kw = "%" + txtSearch.getText().trim() + "%";
        String sql = "SELECT ma_lop, ten_lop, ten_khoa_hoc, giao_vien, phong_hoc, " +
                "si_so_hien_tai, si_so_toi_da, con_trong, trang_thai " +
                "FROM v_si_so_lop " +
                "WHERE (ma_lop LIKE ? OR ten_lop LIKE ? OR ten_khoa_hoc LIKE ? OR giao_vien LIKE ?) " +
                (chkConCho.isSelected() ? "AND con_trong > 0 " : "") +
                "ORDER BY ten_lop";
        try {
            DbUtil.query(model, sql, kw, kw, kw, kw);
        } catch (Exception ex) {
            DbUtil.error(this, ex);
        }
    }
}
