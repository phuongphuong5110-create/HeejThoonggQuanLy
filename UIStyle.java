import java.awt.*;
import javax.swing.*;
import javax.swing.border.*;

public class UIStyle {
    public static final Color NAVY = new Color(23, 71, 131);
    public static final Color BLUE = new Color(39, 115, 212);
    public static final Color LIGHT = new Color(243, 248, 255);
    public static final Color BORDER = new Color(218, 230, 245);
    public static final Color TEXT = new Color(35, 59, 85);

    public static void styleButton(JButton b) {
        b.setBackground(BLUE);
        b.setForeground(Color.WHITE);
        b.setFocusPainted(false);
        b.setBorder(new EmptyBorder(9, 14, 9, 14));
        b.setCursor(new Cursor(Cursor.HAND_CURSOR));
    }

    public static JButton button(String text) {
        JButton b = new JButton(text);
        styleButton(b);
        return b;
    }

    /** Thẻ thống kê: nhãn nhỏ + giá trị lớn. Trả về JLabel giá trị để cập nhật sau. */
    public static JLabel statCard(JPanel parent, String name) {
        JPanel c = card();
        c.setLayout(new BoxLayout(c, BoxLayout.Y_AXIS));
        JLabel v = new JLabel("...");
        v.setFont(new Font("SansSerif", Font.BOLD, 20));
        v.setForeground(BLUE);
        c.add(label(name));
        c.add(Box.createVerticalStrut(10));
        c.add(v);
        parent.add(c);
        return v;
    }

    public static JPanel page(String title, String subtitle) {
        JPanel p = new JPanel(new BorderLayout(0, 16));
        p.setBackground(LIGHT);
        p.setBorder(new EmptyBorder(22, 24, 22, 24));
        JPanel header = new JPanel();
        header.setBackground(LIGHT);
        header.setLayout(new BoxLayout(header, BoxLayout.Y_AXIS));
        JLabel h = new JLabel(title);
        h.setFont(new Font("SansSerif", Font.BOLD, 24));
        h.setForeground(NAVY);
        JLabel sub = new JLabel(subtitle);
        sub.setFont(new Font("SansSerif", Font.PLAIN, 13));
        sub.setForeground(new Color(105, 125, 148));
        header.add(h);
        header.add(Box.createVerticalStrut(6));
        header.add(sub);
        p.add(header, BorderLayout.NORTH);
        return p;
    }

    public static JPanel card() {
        JPanel p = new JPanel();
        p.setBackground(Color.WHITE);
        p.setBorder(new CompoundBorder(
            new LineBorder(BORDER, 1, true),
            new EmptyBorder(16, 16, 16, 16)
        ));
        return p;
    }

    public static JLabel label(String text) {
        JLabel l = new JLabel(text);
        l.setForeground(TEXT);
        l.setFont(new Font("SansSerif", Font.PLAIN, 13));
        return l;
    }

    public static JTextField field() {
        JTextField f = new JTextField(18);
        f.setPreferredSize(new Dimension(180, 32));
        return f;
    }
}
