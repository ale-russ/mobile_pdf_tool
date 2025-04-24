import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_tool/screens/merge_pdf.dart';
import 'package:pdf_tool/screens/pdf_editor_screen.dart';

import '../utils/app_colors.dart';
import '../widgets/tab_button.dart';
import 'scan_pdf.dart';

class MainTabViewScreen extends ConsumerStatefulWidget {
  const MainTabViewScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _MainTabViewScreenState();
}

class _MainTabViewScreenState extends ConsumerState<MainTabViewScreen> {
  int selectedTab = 2;
  PageStorageBucket storageBucket = PageStorageBucket();
  Widget selectPageView = PdfEditorScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: const Color(0xfff5f5f5),
      body: PageStorage(
        bucket: storageBucket,
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.8,
          child: selectPageView,
        ),
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.miniCenterDocked,
      floatingActionButton: SizedBox(
        height: 55,
        width: 55,
        child: FloatingActionButton(
          onPressed: () {
            if (selectedTab != 2) {
              selectedTab = 2;
              selectPageView = PdfEditorScreen();
            }
            if (mounted) {
              setState(() {});
            }
          },
          shape: CircleBorder(),
          backgroundColor:
              selectedTab == 2 ? TColor.primary : TColor.placeholder,
          child: Icon(Icons.home_rounded, size: 25, color: TColor.textfield),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        shadowColor: TColor.black,
        surfaceTintColor: TColor.textfield,
        color: TColor.white,
        elevation: 1,
        notchMargin: 8,
        shape: const CircularNotchedRectangle(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            TabButton(
              icon: Icons.scanner,
              onTap: () {
                if (selectedTab != 0) {
                  selectedTab = 0;
                  selectPageView = ScanPDFScreen();
                }
                if (mounted) {
                  setState(() {});
                }
              },
              isSelected: selectedTab == 0,
              title: "Scan Document",
            ),
            TabButton(
              icon: Icons.call_merge_outlined,
              onTap: () {
                if (selectedTab != 1) {
                  selectedTab = 1;
                  selectPageView = MergePdfScreen();
                }
                if (mounted) {
                  setState(() {});
                }
              },
              isSelected: selectedTab == 1,
              title: "Merge PDF",
            ),
          ],
        ),
      ),
    );
  }
}
