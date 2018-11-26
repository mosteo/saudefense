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

% Last Modified by GUIDE v2.5 26-Nov-2018 18:06:44

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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function looper(handles)
handles.props.looping = true;
if handles.props.pending
    handles.props.pending = false;
    update_LTI(handles, true);
end
% disp('>')
if isfield(handles, 'sau') && ~handles.props.closing && ~handles.props.busy
    handles.sau.tic()
    handles.sau.iterate();
    
    if handles.props.diff_changed
        handles.sau.difficulty = handles.props.difficulty;
        handles.props.diff_changed = false;
    else
        handles.difficulty.Value = handles.sau.difficulty;
    end
    sdfunc.update_difficulty_panel(handles);
    
    
    if handles.siso_enabled.Value
        handles.sau.update_siso_plot(handles.siso);
    end
    handles.sau.toc()
    sdfunc.update_texts(handles, handles.sau);    
end
handles.props.looping = false;
% disp('<')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
handles.initializing.Position = [0 0 1 1];
drawnow

handles.props = props;
handles.props.busy = true;

axes(handles.diagram);
diagram = imread('diagram.jpg');
dpos    = handles.diagram.Position;
diagram = imresize(diagram, [dpos(4) dpos(3)]);
imshow(diagram);

handles.sau    = saudefense(handles.battle, false);
sau = handles.sau;

handles.closing = false; % True after figure starts closing
handles.looping = false; % True while timer callback running
% Apparently there's no way to do proper syncing in matlab...
% This is thread unsafe and racy but might be better than nothing

handles.difficulty.Value = sau.difficulty;
sdfunc.update_difficulty_panel(handles);

handles.looper = timer;
handles.looper.ExecutionMode = 'fixedRate';
handles.looper.Period = handles.sau.T;
handles.looper.UserData = handles.sau;
handles.looper.TimerFcn = @(~,~)looper(handles);
handles.looper.StartDelay = 0.2;

handles.autoaim.Value = sau.auto_aim;
handles.autofire.Value = sau.auto_fire;

handles.period.String = sprintf('%g', sau.T);
handles.Kp.String = sprintf('%g', sau.C_Kp);
handles.Ki.String = sprintf('%g', sau.C_Ki);
handles.Kd.String = sprintf('%g', sau.C_Kd);
handles.tau.String = sprintf('%g', sau.tau);

guidata(hObject, handles);

update_LTI(handles);

handles.props.busy   = false;
handles.start.Enable = 'on';
handles.initializing.Visible = 'off';
disp('Ready');

% while true
%     handles.sau.iterate;
% end

% UIWAIT makes sdgui wait for user response (see UIRESUME)
%uiwait(handles.window);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% --- Outputs from this function are returned to the command line.
function varargout = sdgui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
%varargout{1} = handles.output;
varargout{1} = [];



function Kp_Callback(hObject, eventdata, handles)
% hObject    handle to Kp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
update_LTI(handles);


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
handles.props.busy = true;
if ~handles.props.running
    handles.start.String = 'Pause';
    handles.props.running = true;
    start(handles.looper);
else       
    handles.start.String = 'GO!';    
    stop(handles.looper);
    handles.props.running = false;
end
handles.start.Enable = 'off';
drawnow
handles.start.Enable = 'on';
handles.props.busy = false;


% --- Executes during object deletion, before destroying properties.
function window_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to window (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isfield(handles, 'looper') && isvalid(handles.looper)
    stop(handles.looper);
    delete(handles.looper);
end


% --- Executes on button press in autoaim.
function autoaim_Callback(hObject, eventdata, handles)
% hObject    handle to autoaim (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.sau.auto_aim = hObject.Value ~= 0;


% --- Executes on button press in autofire.
function autofire_Callback(hObject, eventdata, handles)
% hObject    handle to autofire (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.sau.auto_fire = hObject.Value ~= 0;



function period_Callback(hObject, eventdata, handles)
% hObject    handle to period (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if handles.props.running    
    stop(handles.looper);
end
handles.sau.T = str2double(hObject.String);
if handles.sau.T < 0.001 
    handles.sau.T = 0.001;
    handles.period.String= '0.001';
end
handles.looper.Period = handles.sau.T;
handles.sau.update_LTI();
if handles.props.running
    start(handles.looper);
end

% --- Executes during object creation, after setting all properties.
function period_CreateFcn(hObject, eventdata, handles)
% hObject    handle to period (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function Ki_Callback(hObject, eventdata, handles)
% hObject    handle to Ki (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
update_LTI(handles);


% --- Executes during object creation, after setting all properties.
function Ki_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Ki (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function Kd_Callback(hObject, eventdata, handles)
% hObject    handle to Kd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
update_LTI(handles);


% --- Executes during object creation, after setting all properties.
function Kd_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Kd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function tau_Callback(hObject, eventdata, handles)
% hObject    handle to tau (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
update_LTI(handles);


% --- Executes during object creation, after setting all properties.
function tau_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tau (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function difficulty_Callback(hObject, eventdata, handles)
% hObject    handle to difficulty (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.sau.difficulty     = hObject.Value;
handles.props.diff_changed = true;
handles.props.difficulty   = hObject.Value;

% --- Executes during object creation, after setting all properties.
function difficulty_CreateFcn(hObject, eventdata, handles)
% hObject    handle to difficulty (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function update_LTI(h, force)
if nargin < 2
    force = false;
end
if h.props.running && ~force
    h.props.pending = true;
    return
end
h.updating.Visible = 'on';
drawnow
h.sau.tau  = str2double(h.tau.String);
h.sau.C_Kp = str2double(h.Kp.String);
h.sau.C_Ki = str2double(h.Ki.String);
h.sau.C_Kd = str2double(h.Kd.String);
h.sau.update_LTI();
h.sau.update_response_plot(h.response);
h.sau.update_error_plot(h.error);
h.sau.update_rlocus(h.rlocus, h.rb_continuous.Value ~= 0);
h.updating.Visible = 'off';
drawnow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% --- Executes on button press in rb_continuous.
function rb_continuous_Callback(hObject, eventdata, handles)
% hObject    handle to rb_continuous (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.sau.update_rlocus(handles.rlocus, handles.rb_continuous.Value ~= 0);


% --- Executes on button press in rb_discrete.
function rb_discrete_Callback(hObject, eventdata, handles)
% hObject    handle to rb_discrete (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.sau.update_rlocus(handles.rlocus, handles.rb_continuous.Value ~= 0);


% --- Executes when user attempts to close window.
function window_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to window (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if handles.props.busy; return; end
if handles.props.looping || handles.props.running
    start_Callback(handles.start, eventdata, handles);
    return
end
handles.props.closing = true;
stop(handles.looper);
%delete(handles.looper);
delete(hObject);


% --- Executes on button press in siso_enabled.
function siso_enabled_Callback(hObject, eventdata, handles)
% hObject    handle to siso_enabled (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of siso_enabled
