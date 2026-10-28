import java.awt.*;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import javax.swing.*;
import javax.swing.table.DefaultTableModel;

/** Báo cáo học phí: giống giao diện cũ (3 thẻ tổng + bảng + lọc còn nợ), dữ liệu từ view v_cong_no. */
public class BaoCaoHocPhiPanel extends JPanel implements Reloadable {
    private final JLabel lblTong, lblDaThu, lblConNo;
    private final DefaultTableModel model = DbUtil.readOnlyModel();
    private boolean chiConNo = false;

    public BaoCaoHocPhiPanel() {
        JPanel page = UIStyle.page("Báo cáo học phí", "Tổng hợp tình hình thanh toán và công nợ học viên");
        JPanel body = new JPanel(new BorderLayout(0, 14));
        body.setOpaque(false);

        JPanel summary = new JPanel(new GridLayout(1, 3, 12, 0));
        summary.setOpaque(false);
        lblTong  = UIStyle.statCard(summary, "Tổng học phí");
        lblDaThu = UIStyle.statCard(summary, "Đã thanh toán");
        lblConNo = UIStyle.statCard(summary, "Còn công nợ");
        body.add(summary, BorderLayout.NORTH);

        JTable table = DbUtil.table(model);
        body.add(new JScrollPane(table), BorderLayout.CENTER);

        JPanel buttons = new JPanel(new FlowLayout(FlowLayout.LEFT));
        buttons.setOpaque(false);
        JButton all = UIStyle.button("Tất cả"), debt = UIStyle.button("Chỉ xem còn nợ"),
                export = UIStyle.button("Xuất báo cáo");
        buttons.add(all); buttons.add(debt); buttons.add(export);
        body.add(buttons, BorderLayout.SOUTH);

        all.addActionListener(e -> { chiConNo = false; reload(); });
        debt.addActionListener(e -> { chiConNo = true; reload(); });
        export.addActionListener(e -> DbUtil.exportCsv(this, table, "bao_cao_hoc_phi"));

        page.add(body, BorderLayout.CENTER);
        setLayout(new BorderLayout());
        add(page);
        reload();
    }

    @Override
    public void reload() {
        try (Connection c = databaseconnection.getConnection();
             PreparedStatement ps = c.prepareStatement(
                     "SELECT SUM(tong_hoc_phi), SUM(da_thu), SUM(con_no) FROM v_cong_no");
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                lblTong.setText(DbUtil.money(rs.getBigDecimal(1)));
                lblDaThu.setText(DbUtil.money(rs.getBigDecimal(2)));
                lblConNo.setText(DbUtil.money(rs.getBigDecimal(3)));
            }
            DbUtil.query(model,
                "SELECT ma_hv, ho_ten, ten_lop, tong_hoc_phi, da_thu, con_no, " +
                "       IF(con_no = 0, 'Đã thanh toán', 'Còn nợ') AS trang_thai " +
                "FROM v_cong_no " + (chiConNo ? "WHERE con_no > 0 " : "") +
                "ORDER BY ma_hv, ten_lop");
        } catch (Exception ex) {
            DbUtil.error(this, ex);
        }
    }
}
