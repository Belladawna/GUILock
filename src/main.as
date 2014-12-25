import com.GameInterface.DistributedValue;
import com.Utils.GlobalSignal;
import com.GameInterface.Tooltip.TooltipData;
import com.GameInterface.Tooltip.TooltipInterface;
import com.GameInterface.Tooltip.TooltipManager;
import com.GameInterface.WaypointInterface;
import com.Utils.HUDController;
import mx.utils.Delegate;

var ModVersion:String = "0.60";

var m_VTIOIsLoadedMonitor:DistributedValue;

var VTIOAddonInfo:String = "GUILock|Belladawna|" + ModVersion + "||_root.guilock_guilock.m_Icon";

var m_MinimapEditModeMask:MovieClip;

function OnModuleActivated()
{
	
	setTimeout(KillQ, 2000);
	
}

function KillQ()
{
	com.Utils.GlobalSignal.SignalSetGUIEditMode.Emit(false);
	
}

function onLoad()
{
	
	ViTOHook();
	
	m_Icon.m_Unlocked._visible = false;
	
	GlobalSignal.SignalSetGUIEditMode.Connect(SlotSetGUIEditMode, this);
	GlobalSignal.SignalScryTimerLoaded.Connect(SlotScryTimerLoaded, this);
	GlobalSignal.SignalScryCounterLoaded.Connect(SlotScryCounterLoaded, this);
	
	m_MinimapScaleMonitor = DistributedValue.Create("MinimapScale");
	
	m_MinimapEditModeMask.onPress = Delegate.create(this, SlotEditMaskPressed);
	m_MinimapEditModeMask.onRelease = m_MinimapEditModeMask.onReleaseOutside = Delegate.create(this, SlotEditMaskReleased);
	m_MinimapEditModeMask._visible = false;
	
	setTimeout(function () { com.Utils.GlobalSignal.SignalSetGUIEditMode.Emit(false); }, 3000);

}


function SlotScryTimerLoaded(loaded:Boolean)
{
	m_ScryTimerActive = loaded;
	GlobalSignal.SignalSetGUIEditMode.Emit(m_Icon.m_Unlocked._visible);
}

function SlotScryCounterLoaded(loaded:Boolean)
{
	m_ScryCounterActive = loaded;
	GlobalSignal.SignalSetGUIEditMode.Emit(m_Icon.m_Unlocked._visible);
}

function SlotSetGUIEditMode(edit:Boolean)
{	
	m_MinimapEditModeMask._visible = edit;
	if(edit)
	{
		LayoutEditModeMask();
		WaypointInterface.ForceShowMinimap(true);
	}
	else
	{
		WaypointInterface.ForceShowMinimap(false);
	}
}

function SlotEditMaskPressed()
{
	//com.GameInterface.UtilsBase.PrintChatText("Map Clicked");
	var scale:Number = DistributedValue.GetDValue("MinimapScale", 100) / 100;
	m_MinimapEditModeMask.startDrag(false, 0, 0, Stage.width - m_MinimapEditModeMask._width + 2, Stage.height - m_MinimapEditModeMask._height);
	this.onMouseMove = function()
	{
		var visibleRect:flash.geom.Rectangle = Stage["visibleRect"];
		WaypointInterface.MoveMinimap(m_MinimapEditModeMask._y, visibleRect.right - (m_MinimapEditModeMask._x + m_MinimapEditModeMask._width));
	}
}

function SlotEditMaskReleased()
{
	m_MinimapEditModeMask.stopDrag();
	this.onMouseMove = function(){}
	
	var visibleRect:flash.geom.Rectangle = Stage["visibleRect"];
	var newTopOffset:DistributedValue = DistributedValue.Create( "MinimapTopOffset" );
	var newRightOffset:DistributedValue = DistributedValue.Create( "MinimapRightOffset" );	
	newTopOffset.SetValue(m_MinimapEditModeMask._y);
	newRightOffset.SetValue(visibleRect.right - (m_MinimapEditModeMask._x + m_MinimapEditModeMask._width));
}

function LayoutEditModeMask()
{
	//com.GameInterface.UtilsBase.PrintChatText("LayoutEditMaskMode")
	//This is weird. Because this is going to go off to the old gui system, and the minimap is aligned
	//with the top right of the screen. We store coordinates as an offset from the top right
	//Coordinates are stored as a frame, not an origin, so offsetTop is the gap between the top 
	//of the screen and the top of the minimap, and offsetRight is the gap between the right of the screen
	//and the right of the minimap
	var minimapTopOffset:DistributedValue = DistributedValue.Create( "MinimapTopOffset" );
	var minimapRightOffset:DistributedValue = DistributedValue.Create( "MinimapRightOffset" );
	if (minimapTopOffset.GetValue() == "undefined") { minimapTopOffset.SetValue(20); }
	if (minimapRightOffset.GetValue() == "undefined") { minimapRightOffset.SetValue(0); }
	
	var visibleRect:flash.geom.Rectangle = Stage["visibleRect"];
	
	var scale:Number = DistributedValue.GetDValue("MinimapScale", 100) / 100;
	
	m_MinimapEditModeMask._x = visibleRect.right - minimapRightOffset.GetValue() - (209 - 2) * scale; //209 is the width of the minimap
	m_MinimapEditModeMask._width = (209 + 2) * scale;
	m_MinimapEditModeMask._y = visibleRect.top + minimapTopOffset.GetValue();
	m_MinimapEditModeMask._height = (209 + 2) * scale;
}


function ToggleGUILock() : Void
{
	//com.GameInterface.UtilsBase.PrintChatText("ToggleGUILock");
	if (m_Icon.m_Locked._visible)
	{
		//com.GameInterface.UtilsBase.PrintChatText("_visible");
		m_Icon.m_Locked._visible = false;
		m_Icon.m_Unlocked._visible = true;
		if (!m_ScryCounterActive)
		{ 
			m_FakeScryCounter = true;
			_root.LoadFlash("ScryCounter.swf", "ScryCounter" , false, _root.getNextHighestDepth(), 0 ); 
		}
		if (!m_ScryTimerActive)
		{ 
			m_FakeScryTimer = true;
			_root.LoadFlash("ScryTimer.swf", "ScryTimer" , false, _root.getNextHighestDepth(), 0 ); 
		}
		GlobalSignal.SignalSetGUIEditMode.Emit(true);
	}
	else
	{
		//com.GameInterface.UtilsBase.PrintChatText("!_visible");
		m_Icon.m_Locked._visible = true;
		m_Icon.m_Unlocked._visible = false;
		if (m_FakeScryCounter)
		{
			m_FakeScryCounter = false;
			_root.UnloadFlash("ScryCounter");
		}
		if (m_FakeScryTimer)
		{
			m_FakeScryTimer = false;
			_root.UnloadFlash("ScryTimer");
		}
		GlobalSignal.SignalSetGUIEditMode.Emit(false);
	}
}

function onUnload():Void
{
    clearInterval(m_UpdateInterval);
	if (m_FakeScryCounter)
	{
		_root.UnloadFlash("ScryCounter");
	}
	if (m_FakeScryTimer)
	{
		_root.UnloadFlash("ScryTimer");
	}
}

function ViTOHook()
{
	
	
	///////////////////////////////////////////
	////Crap for Viper's Bar
	///////////////////////////////////////////
	
	
	//Crap for Viper's Bar
	
	// Setting up the VTIO loaded monitor.
	m_VTIOIsLoadedMonitor = DistributedValue.Create("VTIO_IsLoaded");
	m_VTIOIsLoadedMonitor.SignalChanged.Connect(SlotCheckVTIOIsLoaded, this);
	
	
	// Setting up the monitor for your option window state.
	//m_OptionWindowState = DistributedValue.Create("AEGISHelper_OptionWindowOpen");
	//m_OptionWindowState.SignalChanged.Connect(SlotOptionWindowState, this);
	
	// Make sure the game doesn't think the window is open if the game was reloaded with it open. Can also be placed in OnModuleDeactivated() if that's used.
	//DistributedValue.SetDValue("AEGISHelper_OptionWindowOpen", false);

	// Setting up your icon.
	m_Icon = attachMovie("LockIcon", "m_Icon", getNextHighestDepth());
	m_Icon._width = 18;
	m_Icon._height = 18;
	m_Icon.onMousePress = function(buttonID) {
		if (buttonID == 1) {
			//Left Button Stuff
			ToggleGUILock();
		} else if (buttonID == 2) {
			//DumpStats();
			// Do right mouse button stuff..
		}
	}

	m_Icon.onRollOver = function() {
		if (m_Tooltip != undefined) m_Tooltip.Close();
        var tooltipData:TooltipData = new TooltipData();
		tooltipData.AddAttribute("", "<font face='_StandardFont' size='13' color='#FF8000'><b>GUILock " + ModVersion + " by Belladawna</b></font>");
        tooltipData.AddAttributeSplitter();
        tooltipData.AddAttribute("", "");
        tooltipData.AddAttribute("", "<font face='_StandardFont' size='12' color='#FFFFFF'>Left click to toggle GUIEditing</font>");
        tooltipData.m_Padding = 4;
        tooltipData.m_MaxWidth = 210;
		m_Tooltip = TooltipManager.GetInstance().ShowTooltip(undefined, TooltipInterface.e_OrientationVertical, 0, tooltipData);
	}
	m_Icon.onRollOut = function() {
		if (m_Tooltip != undefined)	m_Tooltip.Close();
	}

	// Start the compass check.
	m_CompassCheckTimerID = setInterval(PositionIcon, 100);
	PositionIcon();

	// Check if VTIO is loaded (if it loaded before this add-on was).
	SlotCheckVTIOIsLoaded();
	
	
	//////////////////////////////////////////////////
	//////End Crap for Viper's Bar
	//////////////////////////////////////////////////


	
}

///////////////////////////
//Functions for Viper's Bar
///////////////////////////


// The compass check function.
function PositionIcon() {
	m_CompassCheckTimerCount++;
	if (m_CompassCheckTimerCount > m_CompassCheckTimerLimit) clearInterval(m_CompassCheckTimerID);
	if (_root.compass._x > 0) {
		clearInterval(m_CompassCheckTimerID);
		m_Icon._x = _root.compass._x - 154;
		m_Icon._y = _root.compass._y + 0;
	}
}

// The function that checks if VTIO is actually loaded and if it is sends the add-on information defined earlier.
// This function will also get called if VTIO loads after your add-on. Make sure not to remove the check for seeing if the value is actually true.
function SlotCheckVTIOIsLoaded() {
	if (DistributedValue.GetDValue("VTIO_IsLoaded")) DistributedValue.SetDValue("VTIO_RegisterAddon", VTIOAddonInfo);
}