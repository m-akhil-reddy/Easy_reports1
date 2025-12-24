import 'package:flutter/material.dart';
class wantpage extends StatelessWidget {
  const wantpage({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return Container(
      height: height * 0.5,
      width: width,
      padding: EdgeInsets.symmetric(horizontal: width * 0.05, vertical: height * 0.02),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            Container(
              width: width * 0.12,
              height: height * 0.006,
              margin: EdgeInsets.only(bottom: height * 0.02),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text('  What do you want to add', style: TextStyle(fontSize: width * 0.05, fontWeight: FontWeight.bold)),
            _iop('Add Notes', iconbutton: IconButton(onPressed: (){}, icon: Icon(Icons.arrow_forward, size: width * 0.06))),
            _iop('Add Shift Log', iconbutton: IconButton(onPressed: (){}, icon: Icon(Icons.arrow_forward, size: width * 0.06))),
            _iop('Add Event', iconbutton: IconButton(onPressed: (){}, icon: Icon(Icons.arrow_forward, size: width * 0.06))),
            _iop('Add Remainder', iconbutton: IconButton(onPressed: (){}, icon: Icon(Icons.arrow_forward, size: width * 0.06))),
            _iop('Add Other', iconbutton: IconButton(onPressed: (){}, icon: Icon(Icons.arrow_forward, size: width * 0.06))),
          ],
        ),
      ),
    );
  }
}
Widget _iop(String title, {IconButton? iconbutton}) {
  final width = WidgetsBinding.instance.platformDispatcher.views.first.physicalSize.width / WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
  return Container(
    margin: EdgeInsets.symmetric(vertical: width * 0.015),
    padding: EdgeInsets.symmetric(horizontal: width * 0.04, vertical: width * 0.035),
    decoration: BoxDecoration(
      color: Colors.grey[200],
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(fontSize: width * 0.042, fontWeight: FontWeight.w500),
          ),
        ),
        SizedBox(
          width: width * 0.09,
          child: iconbutton ?? const SizedBox.shrink(),
        ),
      ],
    ),
  );
}