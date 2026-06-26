import 'base_parser.dart';

class ResumeParser extends BaseParser {
  @override
  Map<String, String> parse(String text) {
    final fields = <String, String>{};
    final lines = text.split('\n').map((l) => l.trim()).toList();

    // 1. Name (usually the first non-empty line)
    String name = '';
    for (final line in lines) {
      if (line.isNotEmpty && line.length > 3 && !line.toLowerCase().contains('resume') && !line.toLowerCase().contains('curriculum')) {
        name = line;
        break;
      }
    }
    fields['Name'] = name;

    // 2. Email
    fields['Email'] = extractEmail(text);

    // 3. Phone
    fields['Phone'] = extractPhone(text);

    // Heuristics for Sections
    int skillsIndex = -1;
    int eduIndex = -1;
    int expIndex = -1;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toLowerCase();
      if (line == 'skills' || line.startsWith('skills:') || line.contains('technical skills') || line.contains('core competencies')) {
        skillsIndex = i;
      } else if (line == 'education' || line.startsWith('education:') || line.contains('academic background') || line.contains('qualifications')) {
        eduIndex = i;
      } else if (line == 'experience' || line.startsWith('experience:') || line.contains('work experience') || line.contains('professional experience') || line.contains('employment')) {
        expIndex = i;
      }
    }

    String captureSection(int startIdx) {
      if (startIdx == -1) return '';
      final captured = <String>[];
      for (int i = startIdx + 1; i < lines.length; i++) {
        final line = lines[i];
        final lower = line.toLowerCase();
        // Stop if we hit another header
        if (lower == 'education' || 
            lower == 'skills' || 
            lower == 'experience' || 
            lower.contains('projects') || 
            lower.contains('languages') || 
            lower.contains('certifications') || 
            (line.isEmpty && captured.length > 4)) {
          break;
        }
        if (line.isNotEmpty) {
          captured.add(line);
        }
      }
      return captured.take(5).join(', ');
    }

    fields['Skills'] = captureSection(skillsIndex);
    fields['Education'] = captureSection(eduIndex);
    fields['Experience'] = captureSection(expIndex);

    return fields;
  }
}
