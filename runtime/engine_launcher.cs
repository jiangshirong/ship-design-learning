// Tiny Windows bridge; the Godot engine is a development dependency, not source content.
using System;
using System.Diagnostics;
using System.IO;
using System.Text;
using System.Windows.Forms;
class EngineLauncher {
 static string Quote(string s) {
  var b=new StringBuilder("\""); int slashes=0;
  foreach(char c in s) {
   if(c=='\\') {slashes++;continue;}
   if(c=='"') {b.Append('\\',slashes*2+1);b.Append(c);slashes=0;continue;}
   b.Append('\\',slashes);slashes=0;b.Append(c);
  }
  b.Append('\\',slashes*2);return b.Append('"').ToString();
 }
 [STAThread] static int Main(string[] args) {
  string engine=Environment.GetEnvironmentVariable("GODOT_BIN");
  if(String.IsNullOrEmpty(engine))engine=Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),"ShipLearningTools","Godot","4.7.2","godot.exe");
  string self=System.Reflection.Assembly.GetExecutingAssembly().Location;
  if(!File.Exists(engine)||String.Equals(Path.GetFullPath(engine),Path.GetFullPath(self),StringComparison.OrdinalIgnoreCase)) {
   MessageBox.Show("请安装 Godot 4.7.2，并将 GODOT_BIN 设置为 Godot 可执行文件的完整路径。\n也可直接用 Godot 打开 project.godot。","缺少 Godot 引擎");return 2;
  }
  var quoted=new string[args.Length];for(int i=0;i<args.Length;i++)quoted[i]=Quote(args[i]);
  var start=new ProcessStartInfo(engine,String.Join(" ",quoted));start.UseShellExecute=false;start.CreateNoWindow=true;start.WorkingDirectory=Environment.CurrentDirectory;
  try {using(var child=Process.Start(start)){child.WaitForExit();return child.ExitCode;}}
  catch(Exception ex){MessageBox.Show(ex.Message,"Godot 启动失败");return 3;}
 }
}
