import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../utils/app_colors.dart';

class SearchBarWidget extends ConsumerStatefulWidget {
  const SearchBarWidget({
    super.key,
    required this.searchController,
    required this.pdfViewerController,
  });

  final TextEditingController searchController;
  final PdfViewerController pdfViewerController;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _SearchBarWidgetState();
}

class _SearchBarWidgetState extends ConsumerState<SearchBarWidget> {
  PdfTextSearchResult? _searchResult;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      height: 40,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Color(0xFFF9FAFB),
        border: Border.all(color: AppColors.borderColor),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppColors.borderColor,
            blurRadius: 6,
            offset: Offset(4, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              alignment: Alignment.center,
              width: MediaQuery.of(context).size.width * 0.6,
              child: TextField(
                style: TextStyle(color: AppColors.textColor),
                controller: widget.searchController,
                decoration: InputDecoration(
                  hintText: 'Search in PDF...',
                  fillColor: AppColors.backgroundColor,
                  border: OutlineInputBorder(borderSide: BorderSide.none),
                  suffixIconConstraints: BoxConstraints(
                    maxHeight: double.infinity,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 4,
                  ),
                  suffixIcon: SizedBox(
                    width: 30,
                    child: IconButton(
                      onPressed: () async {
                        final searchText = widget.searchController.text.trim();

                        if (searchText.isEmpty) return;

                        final result = await widget.pdfViewerController
                            .searchText(searchText);
                        _searchResult = result;
                        setState(() {});
                      },
                      style: IconButton.styleFrom(padding: EdgeInsets.zero),
                      icon: Icon(Icons.search),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(width: 8),
              Container(
                height: 30,
                width: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.backgroundColor),
                ),
                child: ElevatedButton(
                  onPressed:
                      () =>
                          _searchResult?.hasResult == true
                              ? _searchResult?.previousInstance()
                              : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    padding: EdgeInsets.zero,
                  ),
                  child: Icon(Icons.arrow_upward, color: AppColors.white),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 30,
                width: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.backgroundColor),
                ),
                child: ElevatedButton(
                  onPressed:
                      () =>
                          _searchResult?.hasResult == true
                              ? _searchResult?.nextInstance()
                              : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    padding: EdgeInsets.zero,
                  ),
                  child: Icon(Icons.arrow_downward, color: AppColors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
