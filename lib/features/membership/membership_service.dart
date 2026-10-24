import '../../core/api_service.dart';

class MembershipService {
  static Future<bool> checkIsMember() async {
    // Karena API Membership dari temanmu (A) mungkin belum siap,
    // kita gunakan 'return true;' sementara agar game bisa dibuka.
    // Jika API sudah siap: Hapus 'return true;' dan hapus tanda 
    // komentar (/* ... */) di bawahnya.
    return true; 

    /*
    try {
      // Ganti '/membership/status' dengan endpoint dari temanmu (A)
      final response = await ApiService.get('/membership/status');
      if (response['success'] == true && response['data'] != null) {
        return response['data']['is_member'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
    */
  }
}