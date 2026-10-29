/// Dấu tổ hợp (U+0300–U+036F) của chữ dạng NFD, ví dụ chữ dán từ nguồn khác.
final _combiningMarks = RegExp('[̀-ͯ]');

/// Chuẩn hóa tiếng Việt để truy vấn không phân biệt dấu và chữ hoa: bỏ dấu (cả "đ" và chữ NFD),
/// chữ thường, cắt khoảng trắng hai đầu. Dùng chung cho Tìm kiếm (Khám phá) và Tủ đồ.
String normalizeSearch(String value) {
  const accented = 'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
  const plain = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
  final lower = value.toLowerCase();
  return lower
      .split('')
      .map((c) {
        final index = accented.indexOf(c);
        return index < 0 ? c : plain[index];
      })
      .join()
      .replaceAll(_combiningMarks, '')
      .trim();
}
