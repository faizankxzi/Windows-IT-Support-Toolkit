param([switch]$Preview,[switch]$NoShow,[switch]$ElevationAttempted)
. (Join-Path $PSScriptRoot 'Toolkit.Engine.ps1')
$identity=Get-ToolkitIdentity
if (!$identity.Administrator -and !$Preview -and !$NoShow -and !$ElevationAttempted) {
    try {
        $code="& '"+$PSCommandPath.Replace("'","''")+"' -ElevationAttempted"
        $encoded=[Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($code))
        $null=Start-Process powershell.exe -ArgumentList @('-NoProfile','-STA','-WindowStyle','Hidden','-ExecutionPolicy','Bypass','-EncodedCommand',$encoded) -Verb RunAs -ErrorAction Stop
        exit
    } catch { $elevationNote='Elevation was cancelled or unavailable. Diagnostics remain available.' }
}
Add-Type -AssemblyName PresentationFramework,PresentationCore,WindowsBase
if ([Threading.Thread]::CurrentThread.GetApartmentState() -ne 'STA') { throw 'Open this UI with Windows PowerShell -STA, or use Start-ToolkitGUI.bat.' }
[xml]$xaml=@"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
 xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
 Title="IT Support Toolkit" Width="960" Height="760" MinWidth="780" MinHeight="580"
 WindowStartupLocation="CenterScreen" Background="#F2F7FA" FontFamily="Segoe UI" FontSize="13">
 <Window.Resources>
  <LinearGradientBrush x:Key="Brand" StartPoint="0,0" EndPoint="1,1"><GradientStop Color="#238FBB" Offset="0"/><GradientStop Color="#169FA5" Offset="0.5"/><GradientStop Color="#4EB58D" Offset="1"/></LinearGradientBrush>
  <LinearGradientBrush x:Key="PageBackground" StartPoint="0,0" EndPoint="1,1"><GradientStop Color="#E1F2F5" Offset="0"/><GradientStop Color="#F4F8FB" Offset="0.55"/><GradientStop Color="#FAF1E8" Offset="1"/></LinearGradientBrush>
  <Style TargetType="TextBlock"><Setter Property="Foreground" Value="#25313F"/><Setter Property="TextWrapping" Value="Wrap"/></Style>
  <Style TargetType="Button">
   <Setter Property="Padding" Value="18,10"/><Setter Property="Margin" Value="0,0,8,8"/><Setter Property="FontWeight" Value="SemiBold"/>
   <Setter Property="Background" Value="White"/><Setter Property="BorderBrush" Value="#CBD4DF"/><Setter Property="Foreground" Value="#25313F"/>
   <Setter Property="HorizontalContentAlignment" Value="Left"/><Setter Property="Cursor" Value="Hand"/>
   <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button">
    <Border x:Name="ButtonBorder" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="1" CornerRadius="24" RenderTransformOrigin="0.5,0.5">
     <Border.RenderTransform><TransformGroup><ScaleTransform/><TranslateTransform/></TransformGroup></Border.RenderTransform>
     <Grid><Border x:Name="Sweep" Background="{TemplateBinding BorderBrush}" CornerRadius="24" Opacity="0.16" RenderTransformOrigin="0,0.5"><Border.RenderTransform><ScaleTransform ScaleX="0"/></Border.RenderTransform></Border><ContentPresenter Margin="{TemplateBinding Padding}" VerticalAlignment="Center" HorizontalAlignment="{TemplateBinding HorizontalContentAlignment}"/></Grid>
    </Border>
    <ControlTemplate.Triggers>
     <Trigger Property="IsMouseOver" Value="True">
      <Trigger.EnterActions><BeginStoryboard><Storyboard>
       <DoubleAnimation Storyboard.TargetName="Sweep" Storyboard.TargetProperty="RenderTransform.ScaleX" To="1" Duration="0:0:0.25"/>
       <DoubleAnimation Storyboard.TargetName="ButtonBorder" Storyboard.TargetProperty="RenderTransform.Children[1].Y" To="-1" Duration="0:0:0.15"/>
      </Storyboard></BeginStoryboard></Trigger.EnterActions>
      <Trigger.ExitActions><BeginStoryboard><Storyboard>
       <DoubleAnimation Storyboard.TargetName="Sweep" Storyboard.TargetProperty="RenderTransform.ScaleX" To="0" Duration="0:0:0.2"/>
       <DoubleAnimation Storyboard.TargetName="ButtonBorder" Storyboard.TargetProperty="RenderTransform.Children[1].Y" To="0" Duration="0:0:0.15"/>
      </Storyboard></BeginStoryboard></Trigger.ExitActions>
     </Trigger>
     <Trigger Property="IsPressed" Value="True"><Trigger.EnterActions><BeginStoryboard><Storyboard><DoubleAnimation Storyboard.TargetName="ButtonBorder" Storyboard.TargetProperty="RenderTransform.Children[0].ScaleX" To="0.97" Duration="0:0:0.08"/><DoubleAnimation Storyboard.TargetName="ButtonBorder" Storyboard.TargetProperty="RenderTransform.Children[0].ScaleY" To="0.97" Duration="0:0:0.08"/></Storyboard></BeginStoryboard></Trigger.EnterActions><Trigger.ExitActions><BeginStoryboard><Storyboard><DoubleAnimation Storyboard.TargetName="ButtonBorder" Storyboard.TargetProperty="RenderTransform.Children[0].ScaleX" To="1" Duration="0:0:0.12"/><DoubleAnimation Storyboard.TargetName="ButtonBorder" Storyboard.TargetProperty="RenderTransform.Children[0].ScaleY" To="1" Duration="0:0:0.12"/></Storyboard></BeginStoryboard></Trigger.ExitActions></Trigger>
     <Trigger Property="IsKeyboardFocused" Value="True"><Setter TargetName="ButtonBorder" Property="BorderBrush" Value="#176EB1"/><Setter TargetName="ButtonBorder" Property="BorderThickness" Value="2"/></Trigger>
     <Trigger Property="IsEnabled" Value="False"><Setter TargetName="ButtonBorder" Property="Opacity" Value="0.45"/><Setter Property="Cursor" Value="Arrow"/></Trigger>
    </ControlTemplate.Triggers>
   </ControlTemplate></Setter.Value></Setter>
  </Style>
  <Style x:Key="Primary" TargetType="Button" BasedOn="{StaticResource {x:Type Button}}"><Setter Property="Background" Value="{StaticResource Brand}"/><Setter Property="BorderBrush" Value="#176EB1"/><Setter Property="Foreground" Value="White"/><Setter Property="HorizontalContentAlignment" Value="Center"/></Style>
  <Style x:Key="Danger" TargetType="Button" BasedOn="{StaticResource {x:Type Button}}"><Setter Property="BorderBrush" Value="#CE5D56"/><Setter Property="Foreground" Value="#B42318"/></Style>
  <Style x:Key="ToolTile" TargetType="Button" BasedOn="{StaticResource {x:Type Button}}">
   <Setter Property="FontWeight" Value="Normal"/>
   <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button">
    <Border x:Name="Tile" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="1" CornerRadius="18" RenderTransformOrigin="0.5,0.5">
     <Border.RenderTransform><TransformGroup><ScaleTransform/><TranslateTransform/></TransformGroup></Border.RenderTransform>
     <Grid><Border x:Name="TileSweep" Background="{TemplateBinding BorderBrush}" Opacity="0.18" CornerRadius="18" RenderTransformOrigin="0.5,1"><Border.RenderTransform><ScaleTransform ScaleY="0"/></Border.RenderTransform></Border><ContentPresenter Margin="{TemplateBinding Padding}" HorizontalAlignment="Stretch" VerticalAlignment="Center"/></Grid>
    </Border>
    <ControlTemplate.Triggers>
     <Trigger Property="IsMouseOver" Value="True">
      <Setter TargetName="Tile" Property="Effect"><Setter.Value><DropShadowEffect Color="#466C83" BlurRadius="15" ShadowDepth="5" Opacity="0.2"/></Setter.Value></Setter>
      <Trigger.EnterActions><BeginStoryboard><Storyboard>
       <DoubleAnimation Storyboard.TargetName="TileSweep" Storyboard.TargetProperty="RenderTransform.ScaleY" To="1" Duration="0:0:0.3"/>
       <DoubleAnimation Storyboard.TargetName="Tile" Storyboard.TargetProperty="RenderTransform.Children[1].Y" To="-3" Duration="0:0:0.2"/>
      </Storyboard></BeginStoryboard></Trigger.EnterActions>
      <Trigger.ExitActions><BeginStoryboard><Storyboard>
       <DoubleAnimation Storyboard.TargetName="TileSweep" Storyboard.TargetProperty="RenderTransform.ScaleY" To="0" Duration="0:0:0.25"/>
       <DoubleAnimation Storyboard.TargetName="Tile" Storyboard.TargetProperty="RenderTransform.Children[1].Y" To="0" Duration="0:0:0.2"/>
      </Storyboard></BeginStoryboard></Trigger.ExitActions>
     </Trigger>
     <Trigger Property="IsPressed" Value="True"><Trigger.EnterActions><BeginStoryboard><Storyboard><DoubleAnimation Storyboard.TargetName="Tile" Storyboard.TargetProperty="RenderTransform.Children[0].ScaleX" To="0.98" Duration="0:0:0.08"/><DoubleAnimation Storyboard.TargetName="Tile" Storyboard.TargetProperty="RenderTransform.Children[0].ScaleY" To="0.98" Duration="0:0:0.08"/></Storyboard></BeginStoryboard></Trigger.EnterActions><Trigger.ExitActions><BeginStoryboard><Storyboard><DoubleAnimation Storyboard.TargetName="Tile" Storyboard.TargetProperty="RenderTransform.Children[0].ScaleX" To="1" Duration="0:0:0.12"/><DoubleAnimation Storyboard.TargetName="Tile" Storyboard.TargetProperty="RenderTransform.Children[0].ScaleY" To="1" Duration="0:0:0.12"/></Storyboard></BeginStoryboard></Trigger.ExitActions></Trigger>
     <Trigger Property="IsKeyboardFocused" Value="True"><Setter TargetName="Tile" Property="BorderThickness" Value="2"/></Trigger>
     <Trigger Property="IsEnabled" Value="False"><Setter TargetName="Tile" Property="Opacity" Value="0.45"/><Setter Property="Cursor" Value="Arrow"/></Trigger>
    </ControlTemplate.Triggers>
   </ControlTemplate></Setter.Value></Setter>
  </Style>
  <Style TargetType="RadioButton">
   <Setter Property="Margin" Value="0,0,0,10"/><Setter Property="Padding" Value="14"/><Setter Property="VerticalContentAlignment" Value="Center"/><Setter Property="Cursor" Value="Hand"/>
   <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="RadioButton">
    <Border x:Name="OptionBorder" Background="White" BorderBrush="#CBD4DF" BorderThickness="1" CornerRadius="12" Padding="{TemplateBinding Padding}">
     <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="25"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions><Grid Width="14" Height="14" HorizontalAlignment="Left" VerticalAlignment="Center"><Ellipse Stroke="#7B8794" StrokeThickness="1"/><Ellipse x:Name="OptionDot" Fill="#176EB1" Margin="3" Visibility="Collapsed"/></Grid><ContentPresenter Grid.Column="1" RecognizesAccessKey="True" VerticalAlignment="Center"/></Grid>
    </Border><ControlTemplate.Triggers>
     <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="OptionBorder" Property="Background" Value="#F1F6FB"/></Trigger>
     <Trigger Property="IsChecked" Value="True"><Setter TargetName="OptionBorder" Property="BorderBrush" Value="#176EB1"/><Setter TargetName="OptionBorder" Property="Background" Value="#E1EFFA"/><Setter TargetName="OptionDot" Property="Visibility" Value="Visible"/></Trigger>
     <Trigger Property="IsKeyboardFocused" Value="True"><Setter TargetName="OptionBorder" Property="BorderThickness" Value="2"/></Trigger>
    </ControlTemplate.Triggers>
   </ControlTemplate></Setter.Value></Setter>
  </Style>
  <Style TargetType="ProgressBar">
   <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="ProgressBar">
    <Border Background="White" CornerRadius="6" ClipToBounds="True">
     <Grid x:Name="PART_Track" ClipToBounds="True">
      <Border x:Name="PART_Indicator" HorizontalAlignment="Left" CornerRadius="6" Background="{StaticResource Brand}">
       <Rectangle Opacity="0.24"><Rectangle.Fill><DrawingBrush TileMode="Tile" Viewport="0,0,24,24" ViewportUnits="Absolute"><DrawingBrush.Transform><TranslateTransform/></DrawingBrush.Transform><DrawingBrush.Drawing><GeometryDrawing Brush="White" Geometry="M 0,0 L 12,0 24,12 24,24 Z M 0,12 L 12,24 0,24 Z"/></DrawingBrush.Drawing></DrawingBrush></Rectangle.Fill><Rectangle.Triggers><EventTrigger RoutedEvent="FrameworkElement.Loaded"><BeginStoryboard><Storyboard><DoubleAnimation Storyboard.TargetProperty="Fill.Transform.X" From="0" To="24" Duration="0:0:0.6" RepeatBehavior="Forever"/></Storyboard></BeginStoryboard></EventTrigger></Rectangle.Triggers></Rectangle>
      </Border>
      <Border x:Name="IndeterminateBand" Visibility="Collapsed" CornerRadius="6"><Border.Background><LinearGradientBrush StartPoint="0,0" EndPoint="1,0"><LinearGradientBrush.RelativeTransform><TranslateTransform/></LinearGradientBrush.RelativeTransform><GradientStop Color="#00238FBB" Offset="0"/><GradientStop Color="#238FBB" Offset="0.03"/><GradientStop Color="#4EB58D" Offset="0.17"/><GradientStop Color="#004EB58D" Offset="0.2"/></LinearGradientBrush></Border.Background></Border>
     </Grid>
    </Border><ControlTemplate.Triggers>
     <Trigger Property="IsIndeterminate" Value="True"><Setter TargetName="PART_Indicator" Property="Visibility" Value="Collapsed"/><Setter TargetName="IndeterminateBand" Property="Visibility" Value="Visible"/>
      <Trigger.EnterActions><BeginStoryboard x:Name="BandAnimation"><Storyboard><DoubleAnimation Storyboard.TargetName="IndeterminateBand" Storyboard.TargetProperty="Background.RelativeTransform.X" From="-0.2" To="1" Duration="0:0:1.4" RepeatBehavior="Forever"/></Storyboard></BeginStoryboard></Trigger.EnterActions>
      <Trigger.ExitActions><StopStoryboard BeginStoryboardName="BandAnimation"/></Trigger.ExitActions>
     </Trigger>
    </ControlTemplate.Triggers>
   </ControlTemplate></Setter.Value></Setter>
  </Style>
  <Style TargetType="DataGrid">
   <Setter Property="AutoGenerateColumns" Value="True"/><Setter Property="IsReadOnly" Value="True"/><Setter Property="CanUserAddRows" Value="False"/>
   <Setter Property="CanUserDeleteRows" Value="False"/><Setter Property="HeadersVisibility" Value="Column"/><Setter Property="GridLinesVisibility" Value="Horizontal"/>
   <Setter Property="RowBackground" Value="White"/><Setter Property="AlternatingRowBackground" Value="#F5F8FC"/>
   <Setter Property="BorderBrush" Value="#D5DBE3"/><Setter Property="Margin" Value="0,8,0,18"/><Setter Property="MinHeight" Value="60"/>
  </Style>
 </Window.Resources>
 <Grid Background="{StaticResource PageBackground}">
  <Grid.RowDefinitions><RowDefinition Height="42"/><RowDefinition Height="*"/></Grid.RowDefinitions>
  <Border Background="{StaticResource Brand}" BorderBrush="#58AAA9" BorderThickness="0,0,0,1">
   <DockPanel Margin="22,0">
    <Border x:Name="PreviewBadge" DockPanel.Dock="Right" Visibility="Collapsed" Background="#FFF3D4" CornerRadius="3" Padding="9,3" VerticalAlignment="Center"><TextBlock Text="Preview - all operations simulated" Foreground="#946400" FontSize="11"/></Border>
    <StackPanel Orientation="Horizontal" VerticalAlignment="Center"><TextBlock Text="&#xE90F;" FontFamily="Segoe MDL2 Assets" Foreground="White" FontSize="18" Margin="0,0,10,0"/><TextBlock Text="IT Support Toolkit" Foreground="White" FontWeight="SemiBold"/></StackPanel>
   </DockPanel>
  </Border>
  <Grid Grid.Row="1" Margin="24">
   <ScrollViewer x:Name="MainPage" VerticalScrollBarVisibility="Auto">
    <StackPanel>
     <Border Background="#ECF5FA" BorderBrush="#D4DAE3" BorderThickness="1" CornerRadius="16" Padding="18" Margin="0,0,0,20">
      <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
       <StackPanel Margin="0,0,20,0"><TextBlock Text="Running as" Foreground="#667085" FontSize="12"/><TextBlock x:Name="AccountText" FontWeight="SemiBold" Margin="0,3,0,4"/><TextBlock x:Name="AdminText" FontSize="12"/><TextBlock x:Name="ComputerText" Foreground="#667085" FontSize="12" Margin="0,6,0,0"/></StackPanel>
       <StackPanel Grid.Column="1"><TextBlock Text="Target user profile" Foreground="#667085" FontSize="12"/><ComboBox x:Name="ProfileCombo" DisplayMemberPath="Name" Margin="0,6,0,7" Padding="7,4"/><TextBlock Text="Chooses whose files profile-based tasks work on. It does not switch the account running the toolkit." FontSize="12" Foreground="#667085"/></StackPanel>
      </Grid>
     </Border>
     <TextBlock x:Name="MainNotice" Foreground="#986700" Margin="0,0,0,12"/>
     <TextBlock Text="DIAGNOSTICS" FontSize="11" Foreground="#667085" Margin="0,0,0,8"/>
     <UniformGrid x:Name="DiagnosticsCards" Columns="2" Margin="0,0,0,12"/>
     <TextBlock Text="CLEANUP" FontSize="11" Foreground="#667085" Margin="0,0,0,8"/>
     <UniformGrid x:Name="CleanupCards" Columns="2" Margin="0,0,0,12"/>
     <TextBlock Text="MAINTENANCE" FontSize="11" Foreground="#667085" Margin="0,0,0,8"/>
     <UniformGrid x:Name="MaintenanceCards" Columns="2"/>
     <StackPanel x:Name="PreviewOptions" Visibility="Collapsed" Margin="0,18,0,0">
      <TextBlock Text="Preview scenario (no Windows operations)" Foreground="#667085" FontSize="12"/>
      <ComboBox x:Name="ScenarioCombo" Margin="0,6,0,0" SelectedIndex="0"><ComboBoxItem Content="Success"/><ComboBoxItem Content="LockedFiles"/><ComboBoxItem Content="ReportFailure"/><ComboBoxItem Content="Failure"/></ComboBox>
     </StackPanel>
    </StackPanel>
   </ScrollViewer>
   <ScrollViewer x:Name="OptionsPage" Visibility="Collapsed" VerticalScrollBarVisibility="Auto">
    <StackPanel>
     <TextBlock x:Name="OptionsTitle" FontSize="23" FontWeight="SemiBold" Margin="0,8,0,8"/>
     <TextBlock x:Name="OptionsDescription" Foreground="#667085" Margin="0,0,0,25"/>
     <Border Background="#F3F6FA" BorderBrush="#D5DBE3" BorderThickness="1" CornerRadius="16" Padding="20">
      <StackPanel><RadioButton x:Name="ModeOne" GroupName="Modes"/><RadioButton x:Name="ModeTwo" GroupName="Modes"/><RadioButton x:Name="ModeThree" GroupName="Modes"/></StackPanel>
     </Border>
     <StackPanel Orientation="Horizontal" Margin="0,25,0,0"><Button x:Name="OptionsContinue" Content="Continue" Style="{StaticResource Primary}"/><Button x:Name="OptionsBack" Content="Go back"/></StackPanel>
    </StackPanel>
   </ScrollViewer>
   <ScrollViewer x:Name="ConfirmPage" Visibility="Collapsed" VerticalScrollBarVisibility="Auto">
    <StackPanel>
     <TextBlock x:Name="ConfirmTitle" FontSize="23" FontWeight="SemiBold" Margin="0,8,0,8"/>
     <TextBlock Text="Deleted files cannot be recovered from the Recycle Bin." Foreground="#667085" Margin="0,0,0,25"/>
     <Border Background="#FFF4D6" BorderBrush="#E9D5A8" BorderThickness="1" CornerRadius="16" Padding="20"><StackPanel><TextBlock Text="This will affect:" FontWeight="SemiBold" Margin="0,0,0,10"/><TextBlock x:Name="ConfirmScope"/></StackPanel></Border>
     <TextBlock x:Name="ConfirmAccount" Margin="0,24,0,0"/>
     <StackPanel Orientation="Horizontal" Margin="0,25,0,0"><Button x:Name="ConfirmStart" Content="Start cleanup" Style="{StaticResource Primary}"/><Button x:Name="ConfirmBack" Content="Go back"/></StackPanel>
    </StackPanel>
   </ScrollViewer>
   <Grid x:Name="TaskPage" Visibility="Collapsed">
    <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
    <StackPanel Margin="0,5,0,18"><TextBlock x:Name="TaskTitle" FontSize="23" FontWeight="SemiBold"/><TextBlock x:Name="TaskIdentity" FontSize="12" Foreground="#667085" Margin="0,12,0,5"/><TextBlock x:Name="TaskScope" FontSize="12" Foreground="#667085"/></StackPanel>
    <Border Grid.Row="1" Background="#E8F3FF" BorderBrush="#CCDDEE" BorderThickness="1" CornerRadius="16" Padding="18">
     <StackPanel><DockPanel><TextBlock x:Name="ElapsedText" DockPanel.Dock="Right" Foreground="#667085" FontSize="12"/><TextBlock x:Name="StageText" FontWeight="SemiBold"/></DockPanel><ProgressBar x:Name="TaskProgress" Height="12" Margin="0,14,0,8" IsIndeterminate="True" Foreground="#0071C5"/><TextBlock x:Name="ProgressNote" FontSize="11" Foreground="#667085"/></StackPanel>
    </Border>
    <StackPanel Grid.Row="2" Margin="0,20,0,12"><TextBlock x:Name="BenefitText"/><TextBlock Text="Activity" Foreground="#667085" FontSize="12" Margin="0,15,0,0"/></StackPanel>
    <Border Grid.Row="3" Background="#14191F" CornerRadius="12" Padding="4"><TextBox x:Name="ActivityBox" Background="Transparent" Foreground="#DFE8F2" BorderThickness="0" Padding="10" FontFamily="Consolas" FontSize="12" IsReadOnly="True" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto"/></Border>
    <Grid Grid.Row="4" Margin="0,18,0,0"><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions><TextBlock x:Name="TaskFooter" Foreground="#667085" FontSize="12" VerticalAlignment="Center"/><Button Grid.Column="1" x:Name="TaskCancel" Style="{StaticResource Danger}" Content="Cancel task" Foreground="#B42318" Margin="15,0,0,0"/></Grid>
   </Grid>
   <Grid x:Name="ResultsPage" Visibility="Collapsed">
    <Grid.RowDefinitions><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
    <ScrollViewer VerticalScrollBarVisibility="Auto"><StackPanel>
     <TextBlock x:Name="ResultTitle" FontSize="23" FontWeight="SemiBold" Margin="0,5,0,14"/>
     <Border x:Name="ResultBanner" BorderThickness="1" CornerRadius="16" Padding="18" Margin="0,0,0,20"><StackPanel><TextBlock x:Name="ResultStatus" FontSize="16" FontWeight="SemiBold"/><TextBlock x:Name="ResultMessage" Margin="0,7,0,0"/></StackPanel></Border>
     <StackPanel x:Name="ResultContent"/>
    </StackPanel></ScrollViewer>
    <Grid Grid.Row="1" Margin="0,18,0,0"><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions><TextBlock x:Name="ResultNotice" Foreground="#986700" VerticalAlignment="Center"/><Button Grid.Column="1" x:Name="ResultBack" Content="Back to toolkit" Style="{StaticResource Primary}" Margin="12,0,0,0"/></Grid>
   </Grid>
  </Grid>
 </Grid>
</Window>
"@
$reader=New-Object Xml.XmlNodeReader($xaml)
$window=[Windows.Markup.XamlReader]::Load($reader)
$ui=@{}
foreach ($node in $xaml.SelectNodes('//*')) {
    $name=$node.GetAttribute('Name','http://schemas.microsoft.com/winfx/2006/xaml')
    if ($name) { $ui[$name]=$window.FindName($name) }
}
$script:Busy=$false;$script:Job=$null;$script:PendingAction=$null;$script:SelectedMode='CheckOnly';$script:LastResult=$null
if ($Preview) {
    $identity=[pscustomobject]@{Account='EXAMPLE\Technician';Computer='EXAMPLE-PC';Administrator=$true}
    $profiles=@([pscustomobject]@{Name='Sample User';Path='C:\Users\Sample User'},[pscustomobject]@{Name='Sample Admin';Path='C:\Users\Sample Admin'})
    $ui.PreviewBadge.Visibility='Visible';$ui.PreviewOptions.Visibility='Visible'
} else {
    try { $profiles=@(Get-ToolkitProfiles | Sort-Object Name) } catch {$profiles=@();$ui.MainNotice.Text='Could not read Windows profiles: '+$_.Exception.Message}
}
$ui.AccountText.Text=$identity.Account
$ui.AdminText.Text=if ($identity.Administrator) {'Administrator'} else {'Not elevated - diagnostics only'}
$ui.AdminText.Foreground=if ($identity.Administrator) {[Windows.Media.Brushes]::ForestGreen} else {[Windows.Media.Brushes]::DarkOrange}
$ui.ComputerText.Text='Computer: '+$identity.Computer
$ui.ProfileCombo.ItemsSource=$profiles
if ($profiles.Count) {
    $initial=@($profiles | Where-Object Path -eq $env:USERPROFILE | Select-Object -First 1)
    if ($initial.Count) {$ui.ProfileCombo.SelectedItem=$initial[0]} else {$ui.ProfileCombo.SelectedIndex=0}
} else {$ui.MainNotice.Text='No registered user profiles are available.'}
if ($elevationNote) {$ui.MainNotice.Text=$elevationNote}

function Show-ToolkitPage {
    param([string]$Name)
    foreach ($page in @('MainPage','OptionsPage','ConfirmPage','TaskPage','ResultsPage')) {$ui[$page].Visibility=if ($page -eq $Name) {'Visible'} else {'Collapsed'}}
    # Animate the new page only; task state and controls switch immediately.
    if ([Windows.SystemParameters]::ClientAreaAnimation) {
        $fade=New-Object Windows.Media.Animation.DoubleAnimation(0,1,[TimeSpan]::FromMilliseconds(250))
        $ui[$Name].BeginAnimation([Windows.UIElement]::OpacityProperty,$fade)
        $move=New-Object Windows.Media.TranslateTransform
        $ui[$Name].RenderTransform=$move
        $slide=New-Object Windows.Media.Animation.DoubleAnimation(8,0,[TimeSpan]::FromMilliseconds(250))
        $slide.EasingFunction=New-Object Windows.Media.Animation.QuadraticEase
        $move.BeginAnimation([Windows.Media.TranslateTransform]::YProperty,$slide)
    }
}
function Get-ToolkitTaskInfo {
    param([string]$Action,[string]$Profile,[string]$Mode)
    $titles=@{Report='Generate Health Report';Temp='Temp Cleanup';Recycle='Recycle Bin Cleanup';GPUpdate='GPUpdate';SFC='SFC Scan';DISM='DISM Repair';Maintenance='Full System Maintenance'}
    $scope=switch ($Action) {
        'Report' {'Read-only measurements. Saves one new report in the Reports folder.'}
        'Temp' {'Selected-profile Temp: '+(Join-Path $Profile 'AppData\Local\Temp')+[Environment]::NewLine+'Windows Temp: '+(Join-Path $env:SystemRoot 'Temp')}
        'Recycle' {"Running account "+$identity.Account+"'s Recycle Bin across its drives. The selected profile does not change this account."}
        'Maintenance' {'Before report; selected-profile and Windows Temp; running-account Recycle Bin; GPUpdate /force; DISM ('+$Mode+'); SFC; after report.'}
        'GPUpdate' {'Computer and running-account Group Policy. Mode: '+$Mode+'.'}
        'SFC' {'Protected system files in the running Windows installation.'}
        'DISM' {'Running Windows image. Mode: '+$Mode+'.'}
    }
    $benefit=switch ($Action) {
        'Report' {'Gives a snapshot of disk space, memory, uptime and profile storage to review or attach to a support ticket.'}
        'Temp' {'Can free space used by leftover app and installer files. Files in use are skipped; Downloads and Outlook files are not deleted.'}
        'Recycle' {'Can free space occupied by previously deleted files in the running account Recycle Bin.'}
        'GPUpdate' {'Refreshes policy settings. Windows may still require a logoff or restart.'}
        'SFC' {'May repair damaged protected Windows files. Completion does not mean that corruption was found or repaired.'}
        'DISM' {'Checks the Windows component store; Full mode may repair it and may require Windows Update access.'}
        'Maintenance' {'Combines diagnostics, cleanup and Windows maintenance, with each outcome recorded separately.'}
    }
    [pscustomobject]@{Title=$titles[$Action];Scope=$scope;Benefit=$benefit}
}
function Get-SelectedToolkitProfile {
    if ($null -eq $ui.ProfileCombo.SelectedItem) {throw 'Select a target user profile.'}
    if ($Preview) {return $ui.ProfileCombo.SelectedItem.Path}
    return Resolve-ToolkitProfile $ui.ProfileCombo.SelectedItem.Path
}
function Select-ToolkitAction {
    param([string]$Action)
    if ($script:Busy) {return}
    $ui.MainNotice.Text=''
    if ($Action -eq 'ReportsFolder') {
        try {
            $folder=Join-Path (Split-Path $PSScriptRoot -Parent) 'Reports'
            if ($Preview) {$ui.MainNotice.Text='Preview: opening folders is simulated.';return}
            if (!(Test-Path -LiteralPath $folder)) {$null=New-Item -Path $folder -ItemType Directory -ErrorAction Stop}
            $null=Get-ToolkitDirectory $folder
            Start-Process -FilePath $folder -ErrorAction Stop
        } catch {$ui.MainNotice.Text=$_.Exception.Message}
        return
    }
    try {$script:TargetProfile=Get-SelectedToolkitProfile} catch {$ui.MainNotice.Text=$_.Exception.Message;return}
    if ($Action -ne 'Report' -and !$identity.Administrator) {$ui.MainNotice.Text='Administrator access is required for this task.';return}
    $script:PendingAction=$Action;$script:SelectedMode=if ($Action -eq 'GPUpdate') {'Force'} else {'CheckOnly'}
    if ($Action -in @('DISM','GPUpdate','Maintenance')) {
        $info=Get-ToolkitTaskInfo $Action $script:TargetProfile $script:SelectedMode
        $ui.OptionsTitle.Text=$info.Title
        $ui.OptionsDescription.Text=if ($Action -eq 'GPUpdate') {'Choose how to refresh policy. No policy folders or saved credentials are deleted.'} else {'Choose the DISM level. CheckHealth and ScanHealth inspect the image; Full also runs RestoreHealth.'}
        if ($Action -eq 'GPUpdate') {
            $ui.ModeOne.Content='Normal - apply policies that changed';$ui.ModeOne.Tag='Normal'
            $ui.ModeTwo.Content='Force - reapply all policies';$ui.ModeTwo.Tag='Force'
            $ui.ModeThree.Visibility='Collapsed';$ui.ModeTwo.IsChecked=$true
        } else {
            $ui.ModeOne.Content='CheckHealth only - quick check for known corruption';$ui.ModeOne.Tag='CheckOnly'
            $ui.ModeTwo.Content='CheckHealth + ScanHealth - deeper inspection';$ui.ModeTwo.Tag='Scan'
            $ui.ModeThree.Content='Full repair - CheckHealth, ScanHealth and RestoreHealth';$ui.ModeThree.Tag='Full'
            $ui.ModeThree.Visibility='Visible';$ui.ModeOne.IsChecked=$true
        }
        Show-ToolkitPage 'OptionsPage'
    } elseif ($Action -in @('Temp','Recycle')) {Show-ToolkitConfirmation}
    else {Start-ToolkitUiTask}
}
function Show-ToolkitConfirmation {
    $info=Get-ToolkitTaskInfo $script:PendingAction $script:TargetProfile $script:SelectedMode
    $ui.ConfirmTitle.Text='Confirm: '+$info.Title;$ui.ConfirmScope.Text=$info.Scope
    $ui.ConfirmAccount.Text='Running as: '+$identity.Account+[Environment]::NewLine+'Selected target profile: '+$script:TargetProfile
    Show-ToolkitPage 'ConfirmPage'
}
function Add-ToolkitActivity {
    param([string]$Text)
    if (!$Text) {return}
    $ui.ActivityBox.AppendText($Text+[Environment]::NewLine)
    if ($ui.ActivityBox.Text.Length -gt 200000) {$ui.ActivityBox.Text=$ui.ActivityBox.Text.Substring($ui.ActivityBox.Text.Length-150000)}
    $ui.ActivityBox.ScrollToEnd()
}
function Start-ToolkitUiTask {
    if ($script:Busy) {return}
    $script:Busy=$true
    $info=Get-ToolkitTaskInfo $script:PendingAction $script:TargetProfile $script:SelectedMode
    $ui.TaskTitle.Text=$info.Title;$ui.TaskIdentity.Text='Running as: '+$identity.Account+'    |    Target profile: '+$script:TargetProfile
    $ui.TaskScope.Text='Affects: '+$info.Scope;$ui.BenefitText.Text='How it may help: '+$info.Benefit
    $ui.StageText.Text='Starting task...';$ui.TaskProgress.IsIndeterminate=$true
    $ui.ProgressNote.Text='Working. This stage has no measurable percentage or remaining time.'
    $ui.ActivityBox.Clear();$ui.TaskFooter.Text='Other tasks are unavailable until this task finishes or stops. Cancelling does not undo changes.';$ui.ElapsedText.Text='Elapsed 00:00'
    $ui.TaskCancel.Content='Cancel task';$ui.TaskCancel.IsEnabled=$true
    Show-ToolkitPage 'TaskPage'
    try {
        $request=@{Action=$script:PendingAction;TargetProfilePath=$script:TargetProfile;Mode=$script:SelectedMode;Confirmed=$true;Preview=[bool]$Preview;Scenario=$ui.ScenarioCombo.SelectedItem.Content}
        $runspace=[Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace()
        $runspace.ApartmentState='STA';$runspace.ThreadOptions='ReuseThread';$runspace.Open()
        $powershell=[Management.Automation.PowerShell]::Create();$powershell.Runspace=$runspace
        $cancellation=New-Object Threading.CancellationTokenSource
        $engine=(Join-Path $PSScriptRoot 'Toolkit.Engine.ps1').Replace("'","''")
        $bootstrap='param($request,$cancellation) $global:ToolkitCancellation=$cancellation; . '''+$engine+'''; Invoke-ToolkitTask @request'
        $null=$powershell.AddScript($bootstrap).AddArgument($request).AddArgument($cancellation)
        $job=[pscustomobject]@{PowerShell=$powershell;Runspace=$runspace;Cancellation=$cancellation;Async=$null;Info=0;Progress=0;Errors=0;Action=$script:PendingAction;Clock=[Diagnostics.Stopwatch]::StartNew()}
        $job.Async=$powershell.BeginInvoke();$script:Job=$job;$timer.Start()
    } catch {
        if ($null -ne $powershell) {$powershell.Dispose()};if ($null -ne $runspace) {$runspace.Dispose()}
        if ($null -ne $cancellation) {$cancellation.Dispose()}
        $script:Busy=$false
        Show-ToolkitResults (New-ToolkitResult $script:PendingAction 'FAILED' ('Task could not start: '+$_.Exception.Message))
    }
}
function Request-ToolkitUiCancellation {
    $job=$script:Job
    if (!$script:Busy -or $null -eq $job -or $job.Async.IsCompleted -or $job.Cancellation.IsCancellationRequested) {return}
    $job.Cancellation.Cancel()
    $ui.TaskCancel.Content='Cancelling...';$ui.TaskCancel.IsEnabled=$false
    $ui.StageText.Text='Cancelling task...';$ui.TaskProgress.IsIndeterminate=$true
    $ui.ProgressNote.Text='Waiting for the running operation to stop. Changes already made are not undone.'
    $ui.TaskFooter.Text='Stopping this task before allowing another one. Some Windows operations must return before they can stop.'
    Add-ToolkitActivity 'Cancel requested. Remaining steps will not start; changes already made remain.'
}
function Add-ToolkitResultTable {
    param([string]$Title,$Rows)
    $items=@($Rows | Where-Object {$null -ne $_})
    if (!$items.Count) {return}
    $label=New-Object Windows.Controls.TextBlock;$label.Text=$Title;$label.FontWeight='SemiBold';$label.Margin='0,5,0,0'
    $null=$ui.ResultContent.Children.Add($label)
    $table=New-Object Windows.Controls.DataGrid;$table.ItemsSource=$items;$table.MaxHeight=360
    $table.Add_AutoGeneratingColumn({
        param($sender,$eventArgs)
        $labels=@{BeforeMB='Before (MB)';AfterMB='After (MB)';FreedMB='Freed (MB)';DeletedCount='Deleted files';SkippedCount='Skipped files';InspectionIssues='Inspection issues';ItemsBefore='Items before';ItemsAfter='Items after'}
        if ($labels.ContainsKey($eventArgs.PropertyName)) {$eventArgs.Column.Header=$labels[$eventArgs.PropertyName]}
    })
    $null=$ui.ResultContent.Children.Add($table)
}
function Show-ToolkitResults {
    param($Result)
    $script:LastResult=$Result
    $info=Get-ToolkitTaskInfo $Result.Action $script:TargetProfile $script:SelectedMode
    $ui.ResultTitle.Text=$info.Title
    $ui.ResultStatus.Text=switch ($Result.Status) {'SUCCESS' {'Task completed'} 'PARTIAL' {'Completed with issues'} 'BUSY' {'Another maintenance task is running'} 'CANCELLED' {'Task cancelled'} default {'Task failed'}}
    if ($Result.PSObject.Properties['OutcomeKnown'] -and !$Result.OutcomeKnown) {$ui.ResultStatus.Text='Outcome unknown'}
    $ui.ResultMessage.Text=$Result.Message
    $ui.ResultBanner.Background=switch ($Result.Status) {'SUCCESS' {'#E7F6ED'} 'FAILED' {'#FFF0F0'} default {'#FFF4D6'}}
    $ui.ResultBanner.BorderBrush=switch ($Result.Status) {'SUCCESS' {'#B7DEC8'} 'FAILED' {'#E6B8B8'} default {'#E9D5A8'}}
    $ui.ResultContent.Children.Clear();$ui.ResultNotice.Text=''
    $identityLine=New-Object Windows.Controls.TextBlock
    $identityLine.Text='Running as: '+$identity.Account+[Environment]::NewLine+'Selected target profile: '+$script:TargetProfile
    $identityLine.Margin='0,0,0,15';$identityLine.Foreground='#667085';$null=$ui.ResultContent.Children.Add($identityLine)
    if ($Result.Action -eq 'Maintenance' -and $Result.Details.MaintenanceStatus) {
        $summary=New-Object Windows.Controls.TextBlock
        $summary.Text='Maintenance: '+$Result.Details.MaintenanceStatus+'    |    Report generation: '+$Result.Details.ReportStatus
        $summary.FontWeight='SemiBold';$summary.Margin='0,0,0,15';$null=$ui.ResultContent.Children.Add($summary)
    }
    Add-ToolkitResultTable 'Measurements / cleanup before and after' $Result.Details.Rows
    Add-ToolkitResultTable 'Maintenance tasks' $Result.Details.TaskResults
    Add-ToolkitResultTable 'Report-generation outcomes' $Result.Details.ReportResults
    foreach ($report in $Result.Details.Reports) {
        if (!$report.Path) {continue}
        $button=New-Object Windows.Controls.Button;$button.Content='Open report: '+$report.Label;$button.Tag=$report.Path;$button.Margin='0,0,0,10'
        $button.Add_Click({
            param($sender,$eventArgs)
            try {
                if (!(Test-Path -LiteralPath $sender.Tag -PathType Leaf)) {throw 'The saved report is no longer available.'}
                Start-Process -FilePath $sender.Tag -ErrorAction Stop
            } catch {$ui.ResultNotice.Text='Could not open report: '+$_.Exception.Message}
        })
        $null=$ui.ResultContent.Children.Add($button)
    }
    if ($ui.ActivityBox.Text) {
        $details=New-Object Windows.Controls.Expander;$details.Header='Activity output';$details.Margin='0,8,0,10'
        $text=New-Object Windows.Controls.TextBox;$text.Text=$ui.ActivityBox.Text;$text.IsReadOnly=$true
        $text.FontFamily='Consolas';$text.FontSize=12;$text.TextWrapping='Wrap';$text.Background='#14191F';$text.Foreground='#DFE8F2';$text.Padding='14'
        $text.VerticalScrollBarVisibility='Auto';$text.MaxHeight=300;$details.Content=$text;$null=$ui.ResultContent.Children.Add($details)
    }
    Show-ToolkitPage 'ResultsPage'
}
function Update-ToolkitUiTask {
    if ($null -eq $script:Job) {return}
    $job=$script:Job
    while ($job.Info -lt $job.PowerShell.Streams.Information.Count) {Add-ToolkitActivity $job.PowerShell.Streams.Information[$job.Info].MessageData.ToString();$job.Info++}
    while ($job.Errors -lt $job.PowerShell.Streams.Error.Count) {Add-ToolkitActivity ('Error: '+$job.PowerShell.Streams.Error[$job.Errors].ToString());$job.Errors++}
    while ($job.Progress -lt $job.PowerShell.Streams.Progress.Count) {
        $progress=$job.PowerShell.Streams.Progress[$job.Progress];$job.Progress++
        if ($progress.RecordType -eq 'Completed') {continue}
        $ui.StageText.Text=$progress.Activity
        if ($progress.PercentComplete -ge 0) {$ui.TaskProgress.IsIndeterminate=$false;$ui.TaskProgress.Value=$progress.PercentComplete;$ui.ProgressNote.Text=$progress.Status+' ('+$progress.PercentComplete+'%)'}
        else {$ui.TaskProgress.IsIndeterminate=$true;$ui.ProgressNote.Text='Working. This stage has no measurable percentage or remaining time.'}
    }
    $elapsed=$job.Clock.Elapsed;$ui.ElapsedText.Text='Elapsed '+('{0:00}:{1:00}' -f [math]::Floor($elapsed.TotalMinutes),$elapsed.Seconds)
    if ($job.Cancellation.IsCancellationRequested) {
        $ui.StageText.Text='Cancelling task...';$ui.TaskProgress.IsIndeterminate=$true
        $ui.ProgressNote.Text='Waiting for the running operation to stop. Changes already made are not undone.'
    }
    if (!$job.Async.IsCompleted) {return}
    $script:Job=$null;$timer.Stop()
    try {
        $output=@($job.PowerShell.EndInvoke($job.Async))
        $results=@($output | Where-Object {$_.PSObject.Properties['ToolkitResult'] -and $_.ToolkitResult})
        $codes=@{SUCCESS=0;FAILED=1;PARTIAL=2;CANCELLED=3;BUSY=4}
        if ($results.Count -ne 1 -or $results[0].Action -ne $job.Action -or !$codes.ContainsKey($results[0].Status) -or $results[0].ExitCode -ne $codes[$results[0].Status]) {throw 'No verified completion result was returned. Review the activity output.'}
        $result=$results[0]
    } catch {$result=New-ToolkitResult $job.Action 'FAILED' $_.Exception.Message;$result | Add-Member NoteProperty OutcomeKnown $false}
    finally {$job.PowerShell.Dispose();$job.Runspace.Dispose();$job.Cancellation.Dispose();$job.Clock.Stop();$script:Busy=$false}
    Show-ToolkitResults $result
}
function Add-ToolkitCard {
    param([string]$Name,[string]$Group,[string]$Action,[string]$Title,[string]$Description,[int]$Glyph)
    $button=New-Object Windows.Controls.Button;$button.Tag=$Action;$button.MinHeight=86;$button.HorizontalContentAlignment='Stretch'
    $button.Style=$window.FindResource('ToolTile')
    $color=switch ($Group) {'DiagnosticsCards' {'#159C9F'} 'CleanupCards' {'#D97845'} default {'#3D76C9'}}
    $button.BorderBrush=$color
    $button.Resources['TileColor']=[Windows.Media.BrushConverter]::new().ConvertFromString($color)
    $grid=New-Object Windows.Controls.Grid
    $iconColumn=New-Object Windows.Controls.ColumnDefinition;$iconColumn.Width='52';$null=$grid.ColumnDefinitions.Add($iconColumn)
    $null=$grid.ColumnDefinitions.Add((New-Object Windows.Controls.ColumnDefinition))
    $icon=New-Object Windows.Controls.TextBlock;$icon.FontFamily='Segoe MDL2 Assets';$icon.Text=[string][char]$Glyph;$icon.FontSize=20;$icon.Foreground=$color;$icon.VerticalAlignment='Center';$icon.HorizontalAlignment='Center'
    $blob=New-Object Windows.Controls.Border;$blob.Width=40;$blob.Height=40;$blob.HorizontalAlignment='Left';$blob.VerticalAlignment='Center';$blob.CornerRadius='12';$blob.Background=New-Object Windows.Media.SolidColorBrush([Windows.Media.ColorConverter]::ConvertFromString($color));$blob.Background.Opacity=0.14
    $blob.RenderTransformOrigin='0.5,0.5';$transforms=New-Object Windows.Media.TransformGroup
    $null=$transforms.Children.Add((New-Object Windows.Media.RotateTransform));$null=$transforms.Children.Add((New-Object Windows.Media.ScaleTransform));$blob.RenderTransform=$transforms;$blob.Child=$icon;$null=$grid.Children.Add($blob)
    $button.Resources['TileIcon']=$blob
    $button.Add_MouseEnter({
        param($sender,$eventArgs)
        if (!$sender.IsEnabled) {return}
        $blob=$sender.Resources['TileIcon'];$blob.Background=$sender.Resources['TileColor'];$blob.Child.Foreground='White'
        if ([Windows.SystemParameters]::ClientAreaAnimation) {
            $tilt=New-Object Windows.Media.Animation.DoubleAnimation(-8,[TimeSpan]::FromMilliseconds(250))
            $blob.RenderTransform.Children[0].BeginAnimation([Windows.Media.RotateTransform]::AngleProperty,$tilt)
            $blob.CornerRadius='18,10,16,11'
            foreach ($property in @([Windows.Media.ScaleTransform]::ScaleXProperty,[Windows.Media.ScaleTransform]::ScaleYProperty)) {
                $pulse=New-Object Windows.Media.Animation.DoubleAnimation(1.04,1.08,[TimeSpan]::FromMilliseconds(1200))
                $pulse.AutoReverse=$true;$pulse.RepeatBehavior=[Windows.Media.Animation.RepeatBehavior]::Forever
                $blob.RenderTransform.Children[1].BeginAnimation($property,$pulse)
            }
        }
    })
    $button.Add_MouseLeave({
        param($sender,$eventArgs)
        $blob=$sender.Resources['TileIcon'];$brush=$sender.Resources['TileColor'].Clone();$brush.Opacity=0.14;$blob.Background=$brush;$blob.Child.Foreground=$sender.Resources['TileColor']
        $blob.CornerRadius='12'
        $blob.RenderTransform.Children[0].BeginAnimation([Windows.Media.RotateTransform]::AngleProperty,$null)
        $blob.RenderTransform.Children[1].BeginAnimation([Windows.Media.ScaleTransform]::ScaleXProperty,$null)
        $blob.RenderTransform.Children[1].BeginAnimation([Windows.Media.ScaleTransform]::ScaleYProperty,$null)
    })
    $stack=New-Object Windows.Controls.StackPanel;[Windows.Controls.Grid]::SetColumn($stack,1)
    $heading=New-Object Windows.Controls.TextBlock;$heading.Text=$Title;$heading.FontWeight='SemiBold';$null=$stack.Children.Add($heading)
    $note=New-Object Windows.Controls.TextBlock;$note.Text=$Description;$note.FontSize=12;$note.Foreground='#667085';$note.Margin='0,4,0,0';$null=$stack.Children.Add($note)
    $null=$grid.Children.Add($stack);$button.Content=$grid
    $button.Add_Click({param($sender,$eventArgs);Select-ToolkitAction $sender.Tag})
    $null=$ui[$Group].Children.Add($button);$ui[$Name]=$button
}
Add-ToolkitCard 'ReportButton' 'DiagnosticsCards' 'Report' 'Generate Health Report' 'Disk, RAM, uptime, Temp, Downloads, Recycle Bin and Outlook cache.' 0xE9D9
Add-ToolkitCard 'ReportsButton' 'DiagnosticsCards' 'ReportsFolder' 'Open Reports Folder' 'Shows reports saved by this toolkit.' 0xED25
Add-ToolkitCard 'TempButton' 'CleanupCards' 'Temp' 'Temp Cleanup' 'Removes temporary files from the selected profile and Windows Temp.' 0xE74D
Add-ToolkitCard 'RecycleButton' 'CleanupCards' 'Recycle' 'Recycle Bin Cleanup' 'Permanently empties the running account Recycle Bin.' 0xE777
Add-ToolkitCard 'MaintenanceButton' 'MaintenanceCards' 'Maintenance' 'Full System Maintenance' 'Reports, cleanup, policy refresh, DISM and SFC in sequence.' 0xE90F
Add-ToolkitCard 'GPButton' 'MaintenanceCards' 'GPUpdate' 'GPUpdate' 'Refreshes computer and running-account Group Policy.' 0xE72C
Add-ToolkitCard 'SFCButton' 'MaintenanceCards' 'SFC' 'SFC Scan' 'Checks protected Windows files and may repair damaged files.' 0xE9D9
Add-ToolkitCard 'DISMButton' 'MaintenanceCards' 'DISM' 'DISM Repair' 'Checks or repairs the running Windows image.' 0xE7B8
foreach ($name in @('TempButton','RecycleButton','MaintenanceButton','GPButton','SFCButton','DISMButton')) {$ui[$name].IsEnabled=$identity.Administrator -and $profiles.Count -gt 0}
$ui.ReportButton.IsEnabled=$profiles.Count -gt 0
$ui.OptionsBack.Add_Click({if (!$script:Busy) {Show-ToolkitPage 'MainPage'}})
$ui.ConfirmBack.Add_Click({if (!$script:Busy) {Show-ToolkitPage 'MainPage'}})
$ui.OptionsContinue.Add_Click({
    if ($script:Busy) {return}
    foreach ($name in @('ModeOne','ModeTwo','ModeThree')) {if ($ui[$name].IsChecked) {$script:SelectedMode=$ui[$name].Tag}}
    if ($script:PendingAction -eq 'Maintenance') {Show-ToolkitConfirmation} else {Start-ToolkitUiTask}
})
$ui.ConfirmStart.Add_Click({Start-ToolkitUiTask})
$ui.ResultBack.Add_Click({if (!$script:Busy) {Show-ToolkitPage 'MainPage'}})
$ui.TaskCancel.Add_Click({Request-ToolkitUiCancellation})
$window.Add_Closing({
    param($sender,$eventArgs)
    if ($script:Busy) {
        $eventArgs.Cancel=$true
        $ui.TaskFooter.Text=if ($null -ne $script:Job -and $script:Job.Cancellation.IsCancellationRequested) {'Cancellation is in progress. Wait for the worker to stop before closing.'} else {'This task is still running. Use Cancel task, then wait for its result before closing.'}
    }
})
$timer=New-Object Windows.Threading.DispatcherTimer
$timer.Interval=[TimeSpan]::FromMilliseconds(150)
$timer.Add_Tick({try {Update-ToolkitUiTask} catch {$ui.TaskFooter.Text='The task display could not refresh: '+$_.Exception.Message}})
$area=[Windows.SystemParameters]::WorkArea
$window.MinWidth=[math]::Min(780,$area.Width-30);$window.MinHeight=[math]::Min(580,$area.Height-40)
$window.Width=[math]::Min(960,$area.Width-30);$window.Height=[math]::Min(760,$area.Height-40)
if (!$NoShow) {
    try {$null=$window.ShowDialog()}
    finally {$timer.Stop();if ($null -ne $script:Job -and $script:Job.Async.IsCompleted) {$script:Job.PowerShell.Dispose();$script:Job.Runspace.Dispose();$script:Job.Cancellation.Dispose()}}
}

