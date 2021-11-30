%   Authors: Alejandro R. Mosteo, Danilo Tardioli, Eduardo Montijano
%   Copyright 2018-9999 Monmostar
%   Licensed under GPLv3 https://www.gnu.org/licenses/gpl-3.0.en.html
%

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

% Last Modified by GUIDE v2.5 30-Nov-2021 19:52:41


%% MY PRELIMINARY CHECKS, BEFORE GUI
if ~sdfunc.initialization_check()
    return
end
%%

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

try
    if nargout
        [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
    else
        gui_mainfcn(gui_State, varargin{:});
    end
catch ME
    fprintf(2, '%s\n', getReport(ME, 'extended'));
    close(findall(0, 'tag', 'sdgui_main'), 'force')
end
% End initialization code - DO NOT EDIT

% --- Executes just before sdgui is made visible.
function sdgui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to sdgui (see VARARGIN)

% Choose default command line output for sdgui
handles.output = hObject;

%% VERIFY ARGUMENTS
if size(varargin) ~= 2
    fprintf('Debe proporcionar dos parametros, controlador y planta: sdgui(C, G)\n');
    close(handles.sdgui_main, 'force')
    return
end

handles.props = props();

handles.props.cmd_line = true;
handles.props.arg_C = tf(varargin{1});
handles.props.arg_G = tf(varargin{2});
% We use tf() to ensure the models are basic tfs, as sisotool exports as
% zpk models which are not directly usable by saudefense

% MY OWN INITIALIZATION
guidata(hObject, sdfunc.init(handles));

% UIWAIT makes sdgui wait for user response (see UIRESUME)
%uiwait(handles.sdgui_main);
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
sdfunc.update_LTI(handles);


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


% --- Executes on key press with focus on sdgui_main and none of its controls.
function sdgui_main_KeyPressFcn(~, eventdata, handles)
% hObject    handle to sdgui_main (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
% handles.props.sau.keyPress(eventdata);


% --- Executes on key release with focus on sdgui_main and none of its controls.
function sdgui_main_KeyReleaseFcn(~, eventdata, handles)
% hObject    handle to sdgui_main (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was released, in lower case
%	Character: character interpretation of the key(s) that was released
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) released
% handles    structure with handles and user data (see GUIDATA)
% handles.props.sau.keyRelease(eventdata);


% --- Executes on button press in start.
function start_Callback(hObject, eventdata, handles)
% hObject    handle to start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
sdfunc.start_stop(handles, false)


% --- Executes on button press in autoaim.
function autoaim_Callback(hObject, eventdata, handles)
% hObject    handle to autoaim (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.props.sau.auto_aim = hObject.Value ~= 0;


% --- Executes on button press in autofire.
function autofire_Callback(hObject, eventdata, handles)
% hObject    handle to autofire (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.props.sau.gun.autofire = hObject.Value ~= 0;


function period_Callback(hObject, eventdata, handles)
% hObject    handle to period (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.props.sau.T = str2double(hObject.String);
if handles.props.sau.T < 0.001 
    handles.props.sau.T = 0.001;
    handles.period.String= '0.001';
end

sdfunc.update_LTI(handles);

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
sdfunc.update_LTI(handles);


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
sdfunc.update_LTI(handles);


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
sdfunc.update_LTI(handles);


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
handles.props.sau.difficulty = hObject.Value;
handles.props.competing = false;
sdfunc.update_difficulty_panel(handles);

% --- Executes during object creation, after setting all properties.
function difficulty_CreateFcn(hObject, eventdata, handles)
% hObject    handle to difficulty (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes when user attempts to close sdgui_main.
function sdgui_main_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to sdgui_main (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if handles.props.running
    start_Callback(handles.start, eventdata, handles);
    return
end
delete(hObject);


function sdgui_main_DeleteFcn(~,~,~)


% --- Executes on mouse motion over figure - except title and menu.
function sdgui_main_WindowButtonMotionFcn(hObject, eventdata, handles)
% DOES NOTHING BUT IS NEEDED TO ENABLE FLUID MOUSE COORDS CAPTURE
% See https://www.mathworks.com/help/matlab/ref/matlab.graphics.axis.axes-properties.html


function do_siso_Callback(hObject, eventdata, handles)
% hObject    handle to do_siso (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.props.sau.plot_hist = hObject.Value;
handles.props.sau.draw_fix_axis;


% --- Executes on selection change in pop_controller.
function pop_controller_Callback(hObject, eventdata, handles)
% hObject    handle to pop_controller (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns pop_controller contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pop_controller
sdfunc.init_tfpanels(handles);
sdfunc.update_LTI(handles);


% --- Executes during object creation, after setting all properties.
function pop_controller_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pop_controller (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in pop_plant.
function pop_plant_Callback(hObject, eventdata, handles)
% hObject    handle to pop_plant (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns pop_plant contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pop_plant
sdfunc.init_tfpanels(handles);
sdfunc.update_LTI(handles);

% --- Executes during object creation, after setting all properties.
function pop_plant_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pop_plant (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in competition.
function competition_Callback(hObject, eventdata, handles)
% hObject    handle to competition (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of competition


% --- Executes on button press in compete.
function compete_Callback(hObject, eventdata, handles)
% hObject    handle to compete (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
sdfunc.start_stop(handles, true)


% --- Executes on button press in pb_help.
function pb_help_Callback(hObject, eventdata, handles)
% hObject    handle to pb_help (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
opts.Interpreter = 'none';
opts.WindowStyle = 'modal';
msgbox({'When running in Competition Mode the following changes apply:', ...
    '- The game will end after a hit without shields.', ...
    '- Configuration is frozen during the simulation.'}, ...
    'Value', opts);


% --- Executes on button press in pb_help_gun.
function pb_help_gun_Callback(hObject, eventdata, handles)
% hObject    handle to pb_help_gun (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
opts.Interpreter = 'none';
opts.WindowStyle = 'modal';
msgbox({'Gun states:', ...
    '^ Ready to fire', ...
    'o Arming', ...
    'v Unable to fire due to excessive speed or acceleration', ...
    'x Destroyed'}, ...
    'Value', opts);
