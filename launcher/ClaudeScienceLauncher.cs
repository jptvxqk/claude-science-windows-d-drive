using System;
using System.Diagnostics;
using System.IO;
using System.Text.RegularExpressions;
using System.Threading;

class Program
{
    [STAThread]
    static void Main()
    {
        string root = Path.GetDirectoryName(Process.GetCurrentProcess().MainModule.FileName);
        string profile = Path.Combine(root, "UserProfile");

        Directory.CreateDirectory(Path.Combine(profile, "AppData", "Local"));
        Directory.CreateDirectory(Path.Combine(profile, "AppData", "Roaming"));

        string localAppData = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
        string installDir = Path.Combine(localAppData, "Programs", "ClaudeScience");
        string guiExe = Path.Combine(installDir, "claude-science.exe");
        string cliExe = Path.Combine(installDir, "claude-science.com");

        if (!File.Exists(guiExe) || !File.Exists(cliExe))
            return;

        bool ready = IsDaemonRunning(cliExe, profile);

        if (!ready)
        {
            try
            {
                var gui = new ProcessStartInfo
                {
                    FileName = guiExe,
                    UseShellExecute = false
                };
                gui.EnvironmentVariables["USERPROFILE"] = profile;
                Process.Start(gui);
            }
            catch
            {
                return;
            }

            for (int i = 0; i < 30; i++)
            {
                Thread.Sleep(1000);
                if (IsDaemonRunning(cliExe, profile))
                {
                    ready = true;
                    break;
                }
            }
        }

        if (!ready)
            return;

        string url = GetFreshUrl(cliExe, profile);
        if (String.IsNullOrWhiteSpace(url))
            return;

        OpenStandaloneWindow(url);
    }

    static bool IsDaemonRunning(string cliExe, string profile)
    {
        try
        {
            var psi = new ProcessStartInfo
            {
                FileName = cliExe,
                Arguments = "status",
                UseShellExecute = false,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                CreateNoWindow = true
            };
            psi.EnvironmentVariables["USERPROFILE"] = profile;

            using (var p = Process.Start(psi))
            {
                string output = p.StandardOutput.ReadToEnd();
                p.WaitForExit();
                return output.Contains("\"running\": true");
            }
        }
        catch
        {
            return false;
        }
    }

    static string GetFreshUrl(string cliExe, string profile)
    {
        try
        {
            var psi = new ProcessStartInfo
            {
                FileName = cliExe,
                Arguments = "url",
                UseShellExecute = false,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                CreateNoWindow = true
            };
            psi.EnvironmentVariables["USERPROFILE"] = profile;

            using (var p = Process.Start(psi))
            {
                string output = p.StandardOutput.ReadToEnd();
                p.WaitForExit();

                Match match = Regex.Match(output, @"https?://[^\s]+");
                return match.Success ? match.Value : null;
            }
        }
        catch
        {
            return null;
        }
    }

    static void OpenStandaloneWindow(string url)
    {
        string[] chromePaths =
        {
            Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles),
                "Google", "Chrome", "Application", "chrome.exe"),
            Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.ProgramFilesX86),
                "Google", "Chrome", "Application", "chrome.exe"),
            Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                "Google", "Chrome", "Application", "chrome.exe")
        };

        foreach (string chrome in chromePaths)
        {
            if (File.Exists(chrome))
            {
                Process.Start(new ProcessStartInfo
                {
                    FileName = chrome,
                    Arguments = "--app=\"" + url + "\"",
                    UseShellExecute = true
                });
                return;
            }
        }

        Process.Start(new ProcessStartInfo
        {
            FileName = url,
            UseShellExecute = true
        });
    }
}
