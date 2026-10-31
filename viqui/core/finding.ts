export interface Finding {
  rule: string;
  file: string;
  line: number;
  column: number;
  message: string;
}
