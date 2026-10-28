import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class databaseconnection {
    // useSSL=false, allowPublicKeyRetrieval=true: tránh lỗi xác thực của MySQL 8.x khi chạy local
    private static final String URL = "jdbc:mysql://localhost:3306/trungtamngoaingu"
            + "?useUnicode=true&characterEncoding=UTF-8&useSSL=false"
            + "&allowPublicKeyRetrieval=true&serverTimezone=Asia/Ho_Chi_Minh"
            + "&connectionCollation=utf8mb4_unicode_ci";
    private static final String USER = "root";
    private static final String PASSWORD = ""; // <-- Điền mật khẩu MySQL của bạn vào đây (nếu có)

    /**
     * Ném SQLException thay vì trả về null: trả null làm các màn hình bị
     * NullPointerException khó hiểu, còn ném lỗi thì giao diện báo đúng nguyên nhân.
     */
    public static Connection getConnection() throws SQLException {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException e) {
            throw new SQLException("Chưa thêm mysql-connector-j.jar vào Project Libraries!", e);
        }
        return DriverManager.getConnection(URL, USER, PASSWORD);
    }
}
