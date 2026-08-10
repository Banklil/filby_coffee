import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/auth_service.dart';

/// ຮູບຮ້ານ — ໃຊ້ຮູບທີ່ຮ້ານອັບໂຫລດ ຖ້າຍັງບໍ່ມີຈຶ່ງໃຊ້ໂລໂກ້ Filby.
///
/// ມີບ່ອນດຽວແບບນີ້ ເພື່ອບໍ່ໃຫ້ແຕ່ລະໜ້າໄປ hardcode 'assets/logo.jpeg' ຄືເກົ່າ
/// ແລ້ວລືມອັບເດດເມື່ອຮ້ານປ່ຽນຮູບ.
class ShopLogo extends StatelessWidget {
  final double size;
  final double radius;
  final BoxFit fit;

  /// ສິ່ງທີ່ຈະສະແດງເມື່ອຮ້ານຍັງບໍ່ໄດ້ອັບຮູບ. ຖ້າບໍ່ໃສ່ = ໂລໂກ້ Filby.
  /// ໜ້າບັນຊີສົ່ງຕົວອັກສອນທຳອິດຂອງຊື່ຮ້ານມາແທນ ເພາະເປັນ avatar.
  final Widget? fallback;

  /// ສີພື້ນຫຼັງ — ຮູບຈິງໃຊ້ຂາວ ແຕ່ avatar ຕົວອັກສອນໃຊ້ສີເຂັ້ມ
  final Color background;

  const ShopLogo({
    super.key,
    this.size = 42,
    this.radius = 12,
    this.fit = BoxFit.cover,
    this.fallback,
    this.background = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final url = AuthService.currentUser?.logoUrl;
    final placeholder =
        fallback ?? Image.asset('assets/logo.jpeg', fit: fit);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: url == null && fallback != null ? Colors.transparent : background,
        borderRadius: BorderRadius.circular(radius),
      ),
      clipBehavior: Clip.hardEdge,
      child: url == null
          ? placeholder
          : Image.network(
              url,
              fit: fit,
              // ຮູບຮ້ານໂຫຼດບໍ່ໄດ້ບໍ່ຄວນເຮັດໃຫ້ໜ້າຈໍພັງ — ຖອຍໄປໃຊ້ອັນສຳຮອງ
              errorBuilder: (_, __, ___) => placeholder,
              loadingBuilder: (ctx, child, progress) => progress == null
                  ? child
                  : const Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: FilbyColors.primary),
                      ),
                    ),
            ),
    );
  }
}
