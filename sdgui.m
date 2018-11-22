function varargout = sdgui(varargin)
% SDGUI MATLAB code for sdgui.fig
%      SDGUI, by itself, creates a new SDGUI or raises the existing
%      singleton*.
%
%      H = SDGUI returns the handle to a new SDGUI or the handle to
%      the existing singleton*.
%
%      SDGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SDGUI.M with the given input arguments.
%
%      SDGUI('Property','Value',...) creates a new SDGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before sdgui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to sdgui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help sdgui

% Last Modified by GUIDE v2.5 22-Nov-2018 22:18:22

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @sdgui_OpeningFcn, ...
                   'gui_OutputFcn',  @sdgui_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

function looper(sau)
sau.iterate();

% --- Executes just before sdgui is made visible.
function sdgui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to sdgui (see VARARGIN)

% Choose default command line output for sdgui
handles.output = hObject;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MY OWN INITIALIZATION
diagram = imread('logo.jpg');
axes(handles.diagram);
imshow(diagram);

handles.sau    = saudefense(handles.battle);
sau = handles.sau;

handles.looper = timer;
handles.looper.ExecutionMode = 'fixedRate';
handles.looper.Period = handles.sau.T;
handles.looper.UserData = handles.sau;
handles.looper.TimerFcn = @(~,~)looper(handles.sau);

handles.autoaim.Value = sau.auto_aim;
handles.autofire.Value = sau.auto_fire;

guidata(hObject, handles);
disp('Ready');

% while true
%     handles.sau.iterate;
% end

% UIWAIT makes sdgui wait for user response (see UIRESUME)
uiwait(handles.window);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% --- Outputs from this function are returned to the command line.
function varargout = sdgui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function Kp_Callback(hObject, eventdata, handles)
% hObject    handle to Kp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Kp as text
%        str2double(get(hObject,'String')) returns contents of Kp as a double


% --- Executes during object creation, after setting all properties.
function Kp_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Kp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on key press with focus on window and none of its controls.
function window_KeyPressFcn(~, eventdata, handles)
% hObject    handle to window (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
handles.sau.keyPress(eventdata);


% --- Executes on key release with focus on window and none of its controls.
function window_KeyReleaseFcn(~, eventdata, handles)
% hObject    handle to window (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was released, in lower case
%	Character: character interpretation of the key(s) that was released
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) released
% handles    structure with handles and user data (see GUIDATA)
handles.sau.keyRelease(eventdata);


% --- Executes on button press in start.
function start_Callback(hObject, eventdata, handles)
% hObject    handle to start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if strcmpi(handles.looper.Running, 'off')
    start(handles.looper);
    handles.start.String = 'Pause';    
else
    stop(handles.looper);    
    handles.start.String = 'GO!';    
end
handles.start.Enable = 'off';
drawnow
handles.start.Enable = 'on';


% --- Executes during object deletion, before destroying properties.
function window_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to window (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
stop(handles.looper);
delete(handles.looper);


% --- Executes on button press in autoaim.
function autoaim_Callback(hObject, eventdata, handles)
% hObject    handle to autoaim (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
eventdata
handles.sau.auto_aim = hObject.Value ~= 0;


% --- Executes on button press in autofire.
function autofire_Callback(hObject, eventdata, handles)
% hObject    handle to autofire (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.sau.auto_fire = hObject.Value ~= 0;
