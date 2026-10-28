import java.awt.*;
import java.util.HashMap;
import java.util.Map;
import javax.swing.*;

public class MainFrame extends JFrame {
    private final CardLayout cardLayout = new CardLayout();
    private final JPanel content = new JPanel(cardLayout);
    private final Map<String, JComponent> screens = new HashMap<>();

    public MainFrame() {
        setTitle("Quản lý trung tâm ngoại ngữ");
        setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        setSize(1200, 740);
        setMinimumSize(new Dimension(1000, 620));
        setLocationRelativeTo(null);
        getContentPane().setLayout(new BorderLayout());

        JPanel sidebar = new JPanel();
        sidebar.setBackground(UIStyle.NAVY);
        sidebar.setPreferredSize(new Dimension(225, 0));
        sidebar.setLayout(new BoxLayout(sidebar, BoxLayout.Y_AXIS));
        sidebar.setBorder(BorderFactory.createEmptyBorder(18, 12, 18, 12));

        JLabel brand = new JLabel("<html><b>LANGUAGE CENTER</b><br><font size='3'>Quản lý trung tâm ngoại ngữ</font></html>");
        brand.setForeground(Color.WHITE);
        brand.setBorder(BorderFactory.createEmptyBorder(8, 8, 24, 8));
        sidebar.add(brand);

        addScreen(sidebar, "Trang chủ", "home", new TrangChuPanel());
        addScreen(sidebar, "Nhập liệu học viên", "hocvien", new HocVienPanel());
        addScreen(sidebar, "Nhập liệu đăng ký", "dangky", new DangKyPanel());
        addScreen(sidebar, "Thu học phí", "thuhocphi", new ThuHocPhiPanel());
        addScreen(sidebar, "Tìm học viên", "timhocvien", new TimKiemHocVienPanel());
        addScreen(sidebar, "Tìm lớp học", "timlop", new TimKiemLopPanel());
        addScreen(sidebar, "Báo cáo học viên theo lớp", "baocaohv", new BaoCaoHocVienPanel());
        addScreen(sidebar, "Báo cáo học phí", "baocaohp", new BaoCaoHocPhiPanel());
        sidebar.add(Box.createVerticalGlue());

        getContentPane().add(sidebar, BorderLayout.WEST);
        getContentPane().add(content, BorderLayout.CENTER);
        cardLayout.show(content, "home");
    }

    private void addScreen(JPanel sidebar, String title, String key, JComponent screen) {
        screens.put(key, screen);
        content.add(screen, key);

        JButton b = new JButton(title);
        b.setAlignmentX(Component.LEFT_ALIGNMENT);
        b.setMaximumSize(new Dimension(Integer.MAX_VALUE, 42));
        b.setHorizontalAlignment(SwingConstants.LEFT);
        b.setBackground(UIStyle.NAVY);
        b.setForeground(Color.WHITE);
        b.setBorder(BorderFactory.createEmptyBorder(10, 12, 10, 8));
        b.setFocusPainted(false);
        b.setCursor(new Cursor(Cursor.HAND_CURSOR));
        b.addActionListener(e -> {
            // dữ liệu có thể đã đổi ở màn khác (đăng ký, thu tiền...) -> tải lại khi mở
            if (screen instanceof Reloadable) ((Reloadable) screen).reload();
            cardLayout.show(content, key);
        });
        sidebar.add(b);
        sidebar.add(Box.createVerticalStrut(4));
    }

    public static void main(String[] args) {
        SwingUtilities.invokeLater(() -> new MainFrame().setVisible(true));
    }
}
