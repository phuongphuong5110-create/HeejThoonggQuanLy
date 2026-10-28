import java.awt.*;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import javax.swing.*;

/** Trang chủ: giống giao diện cũ, số liệu lấy từ view v_tong_quan. */
public class TrangChuPanel extends JPanel implements Reloadable {
    private final JLabel lblHocVien, lblLop, lblDaThu;
    private final JLabel lblKetNoi = UIStyle.label(" ");

    public TrangChuPanel() {
        JPanel page = UIStyle.page("Trang chủ", "Hệ thống quản lý trung tâm ngoại ngữ");
        JPanel body = new JPanel(new BorderLayout(0, 16));
        body.setOpaque(false);

        JPanel stats = new JPanel(new GridLayout(1, 3, 14, 0));
        stats.setOpaque(false);
        lblHocVien = UIStyle.statCard(stats, "Học viên");
        lblLop     = UIStyle.statCard(stats, "Lớp học");
        lblDaThu   = UIStyle.statCard(stats, "Học phí đã thu");
        body.add(stats, BorderLayout.NORTH);

        JPanel info = UIStyle.card();
        info.setLayout(new BoxLayout(info, BoxLayout.Y_AXIS));
        JLabel h = new JLabel("Chức năng chính");
        h.setFont(new Font("SansSerif", Font.BOLD, 16));
        h.setForeground(UIStyle.NAVY);
        info.add(h);
        String[] items = {"• Nhập và quản lý thông tin học viên", "• Ghi nhận đăng ký khóa học/lớp học",
                "• Thu học phí theo đợt", "• Tìm kiếm học viên và lớp học",
                "• Xem báo cáo học viên theo lớp và báo cáo học phí"};
        for (String s : items) {
            info.add(Box.createVerticalStrut(10));
            info.add(new JLabel(s));
        }
        body.add(info, BorderLayout.CENTER);
        body.add(lblKetNoi, BorderLayout.SOUTH);

        page.add(body, BorderLayout.CENTER);
        setLayout(new BorderLayout());
        add(page);
        reload();
    }

    @Override
    public void reload() {
        try (Connection c = databaseconnection.getConnection();
             PreparedStatement ps = c.prepareStatement(
                     "SELECT v.*, @@hostname AS may, @@port AS cong, DATABASE() AS csdl, VERSION() AS ban " +
                     "FROM v_tong_quan v");
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                lblHocVien.setText(rs.getString("so_hoc_vien"));
                lblLop.setText(rs.getString("so_lop_mo"));
                lblDaThu.setText(DbUtil.money(rs.getBigDecimal("tong_da_thu")));
                lblKetNoi.setForeground(new Color(30, 130, 60));
                lblKetNoi.setText("● Đã kết nối MySQL " + rs.getString("ban") + " — máy " + rs.getString("may")
                        + ", cổng " + rs.getString("cong") + ", CSDL " + rs.getString("csdl"));
            }
        } catch (Exception ex) {
            lblHocVien.setText("—");
            lblLop.setText("—");
            lblDaThu.setText("—");
            lblKetNoi.setForeground(new Color(190, 40, 40));
            lblKetNoi.setText("● Không kết nối được CSDL: " + ex.getMessage());
            ex.printStackTrace();
        }
    }
}
