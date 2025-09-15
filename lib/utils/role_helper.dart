class RoleHelper {
  static bool isAdmin(String role) => role == "Admin";
  static bool isManager(String role) => role == "Manager";
  static bool isExecutive(String role) => role == "Executive";

  static bool canAccessDashboard(String role) => role == "Admin";
  static bool canAccessOrders(String role) =>
      role == "Admin" || role == "Manager";
  static bool canAccessProducts(String role) =>
      role == "Admin" || role == "Manager";
  static bool canManageProducts(String role) => role == "Admin";
  static bool canAccessPurchases(String role) => role == "Admin";
  static bool canAccessVendors(String role) => role == "Admin";
  static bool canAccessShipments(String role) => true; // everyone
}
