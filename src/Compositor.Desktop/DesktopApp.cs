using Avalonia;
using Avalonia.Controls.ApplicationLifetimes;
using Avalonia.Styling;
using Avalonia.Themes.Fluent;

namespace Compositor.Desktop;

public sealed class DesktopApp : Application
{
    public override void Initialize()
    {
        // The Mac build asks for the dark appearance and draws its own greys on top of it
        // (ContentView's `.preferredColorScheme(.dark)`), so the port does the same rather than
        // following whatever the machine is set to — a light menu bar over a dark canvas was
        // unreadable, and the Mac has no light appearance to match.
        RequestedThemeVariant = ThemeVariant.Dark;
        _theme = new FluentTheme();
        Styles.Add(_theme);
    }

    private FluentTheme? _theme;

    public override void OnFrameworkInitializationCompleted()
    {
        // The palette is moved onto the Mac's once the theme is attached: until then its resources have not
        // been read off its own XAML, and a dictionary with nothing in it has nothing to move.
        if (_theme is { } theme) Skin.Apply(theme);
        if (ApplicationLifetime is IClassicDesktopStyleApplicationLifetime desktop)
        {
            var window = new MainWindow();
            // The Mac build's mark, converted for Windows: the same icon the executable is stamped
            // with through ApplicationIcon, set on the window as well so the title bar and the
            // taskbar button carry it rather than the default. A build that lost the resource still
            // starts, and simply keeps whatever icon the executable already has.
            try
            {
                window.Icon = new Avalonia.Controls.WindowIcon(
                    Avalonia.Platform.AssetLoader.Open(new Uri("avares://Compositor.Desktop/Assets/compositor.ico")));
            }
            catch (Exception)
            {
                // No icon resource in this build; the executable's own icon still applies.
            }
            desktop.MainWindow = window;
        }
        base.OnFrameworkInitializationCompleted();
    }
}
