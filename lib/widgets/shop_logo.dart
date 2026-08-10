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

  const ShopLogo({
    super.key,
    this.size = 42,
    this.radius = 12,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final url = AuthService.currentUser?.logoUrl;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
      clipBehavior: Clip.hardEdge,
      child: url == null
          ? Image.asset('assets/logo.jpeg', fit: fit)
          : Image.network(
              url,
              fit: fit,
              // ຮູບຮ້ານໂຫຼດບໍ່ໄດ້ບໍ່ຄວນເຮັດໃຫ້ໜ້າຈໍພັງ — ຖອຍໄປໃຊ້ໂລໂກ້ແທນ
              errorBuilder: (_, __, ___) =>
                  Image.asset('assets/logo.jpeg', fit: fit),
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
