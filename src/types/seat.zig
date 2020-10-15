const wlr = @import("../wlroots.zig");

const os = @import("std").os;

const wayland = @import("wayland");
const wl = wayland.server.wl;

pub const SerialRange = extern struct {
    min_incl: u32,
    max_incl: u32,
};

pub const SerialRingset = extern struct {
    data: [128]SerialRange,
    end: c_int,
    count: c_int,
};

pub const TouchPoint = extern struct {
    touch_id: i32,
    surface: ?*wlr.Surface,
    client: *wlr.Seat.Client,

    focus_surface: ?*wlr.Surface,
    focus_client: ?*wlr.Seat.Client,
    sx: f64,
    sy: f64,

    surface_destroy: wl.Listener,
    focus_surface_destroy: wl.Listener,
    client_destroy: wl.Listener,

    events: extern struct {
        destroy: wl.Signal,
    },

    /// Seat.TouchState.touch_points
    link: wl.List,
};

pub const Seat = extern struct {
    pub const Client = extern struct {
        client: *wl.Client,
        seat: *Seat,
        /// Seat.clients
        link: wl.List,

        resources: wl.List,
        pointers: wl.List,
        keyboards: wl.List,
        touches: wl.List,
        data_devices: wl.List,

        events: extern struct {
            destroy: wl.Signal,
        },

        serials: SerialRingset,

        extern fn wlr_seat_client_next_serial(client: *Client) u32;
        pub const nextSerial = wlr_seat_client_next_serial;

        extern fn wlr_seat_client_validate_event_serial(client: *Client, serial: u32) bool;
        pub const validateEventSerial = wlr_seat_client_validate_event_serial;

        extern fn wlr_seat_client_from_resource(seat: *wl.Seat) ?*Client;
        pub const fromWlSeat = wlr_seat_client_from_resource;

        extern fn wlr_seat_client_from_pointer_resource(pointer: *wl.Pointer) ?*Client;
        pub const fromWlPointer = wlr_seat_client_from_pointer_resource;
    };

    pub const PointerGrab = extern struct {
        pub const Interface = extern struct {
            enter: fn (
                grab: *PointerGrab,
                surface: *wlr.Surface,
                sx: f64,
                sy: f64,
            ) callconv(.C) void,
            clear_focus: fn (grab: *PointerGrab) callconv(.C) void,
            motion: fn (grab: *PointerGrab, time_msec: u32, sx: f64, sy: f64) callconv(.C) void,
            button: fn (
                grab: *PointerGrab,
                time_msec: u32,
                button: u32,
                state: wlr.ButtonState,
            ) callconv(.C) u32,
            axis: fn (
                grab: *PointerGrab,
                time_msec: u32,
                orientation: wlr.AxisOrientation,
                value: f64,
                value_discrete: i32,
                source: wlr.Pointer.event.Axis.Source,
            ) callconv(.C) void,
            frame: ?fn (grab: *PointerGrab) callconv(.C) void,
            cancel: ?fn (grab: *PointerGrab) callconv(.C) void,
        };

        interface: *const Interface,
        seat: *Seat,
        data: ?*c_void,
    };

    pub const KeyboardGrab = extern struct {
        pub const Interface = extern struct {
            enter: fn (
                grab: *KeyboardGrab,
                surface: *wlr.Surface,
                keycodes: [*]u32,
                num_keycodes: usize,
                modifiers: *wlr.Keyboard.Modifiers,
            ) callconv(.C) void,
            clear_focus: fn (grab: *KeyboardGrab) callconv(.C) void,
            key: fn (grab: *KeyboardGrab, time_msec: u32, key: u32, state: u32) callconv(.C) void,
            modifiers: fn (grab: *KeyboardGrab, modifiers: *wlr.Keyboard.Modifiers) callconv(.C) void,
            cancel: ?fn (grab: *KeyboardGrab) callconv(.C) void,
        };

        interface: *const Interface,
        seat: *Seat,
        data: ?*c_void,
    };

    pub const TouchGrab = extern struct {
        pub const Interface = extern struct {
            down: fn (grab: *TouchGrab, time_msec: u32, point: *TouchPoint) callconv(.C) u32,
            up: fn (grab: *TouchGrab, time_msec: u32, point: *TouchPoint) callconv(.C) void,
            motion: fn (grab: *TouchGrab, time_msec: u32, point: *TouchPoint) callconv(.C) void,
            enter: fn (grab: *TouchGrab, time_msec: u32, point: *TouchPoint) callconv(.C) void,
            cancel: ?fn (grab: *TouchGrab) callconv(.C) void,
        };

        interface: *const Interface,
        seat: *Seat,
        data: ?*c_void,
    };

    pub const PointerState = extern struct {
        seat: *Seat,
        focused_client: ?*Seat.Client,
        focused_surface: ?*wlr.Surface,
        sx: f64,
        sy: f64,

        grab: *PointerGrab,
        default_grab: *PointerGrab,

        buttons: [16]u32,
        button_count: usize,
        grab_button: u32,
        grab_serial: u32,
        grab_time: u32,

        surface_destroy: wl.Listener,

        events: extern struct {
            focus_change: wl.Signal, // event.PointerFocusChange
        },
    };

    pub const KeyboardState = extern struct {
        seat: *Seat,
        keyboard: ?*wlr.Keyboard,

        focused_client: ?*Seat.Client,
        focused_surface: ?*wlr.Surface,

        keyboard_destroy: wl.Listener,
        keyboard_keymap: wl.Listener,
        keyboard_repeat_info: wl.Listener,
        surface_destroy: wl.Listener,

        grab: *KeyboardGrab,
        default_grab: *KeyboardGrab,

        events: extern struct {
            focus_change: wl.Signal, // event.KeyboardFocusChange
        },
    };

    pub const TouchState = extern struct {
        seat: *Seat,
        /// TouchPoint.link
        touch_points: wl.List,

        grab_serial: u32,
        grab_id: u32,

        grab: *TouchGrab,
        default_grab: *TouchGrab,
    };

    pub const event = struct {
        pub const PointerFocusChange = extern struct {
            seat: *Seat,
            old_surface: ?*wlr.Surface,
            new_surface: ?*wlr.Surface,
            sx: f64,
            sy: f64,
        };

        pub const KeyboardFocusChange = extern struct {
            seat: *Seat,
            old_surface: ?*wlr.Surface,
            new_surface: ?*wlr.Surface,
        };

        pub const RequestSetCursor = extern struct {
            seat_client: *Seat.Client,
            surface: ?*wlr.Surface,
            serial: u32,
            hotspot_x: i32,
            hotspot_y: i32,
        };

        pub const RequestSetSelection = extern struct {
            source: ?*wlr.DataSource,
            serial: u32,
        };

        pub const RequestSetPrimarySelection = extern struct {
            source: ?*wlr.PrimarySelectionSource,
            serial: u32,
        };

        pub const RequestStartDrag = extern struct {
            drag: *wlr.Drag,
            origin: *wlr.Surface,
            serial: u32,
        };
    };

    global: *wl.Global,
    server: *wl.Server,
    /// Seat.Client.link
    clients: wl.List,

    name: [*:0]u8,

    capabilities: u32,
    accumulated_capabilities: u32,
    last_event: os.timespec,

    selection_source: ?*wlr.DataSource,
    selection_serial: u32,
    /// wlr.DataOffer.link
    selection_offers: wl.List,

    primary_selection_source: ?*wlr.PrimarySelectionSource,
    primary_selection_serial: u32,

    drag: ?*wlr.Drag,
    drag_source: ?*wlr.DataSource,
    drag_serial: u32,
    /// wlr.DataOffer.link
    drag_offers: wl.List,

    pointer_state: PointerState,
    keyboard_state: KeyboardState,
    touch_state: TouchState,

    display_destroy: wl.Listener,
    selection_source_destroy: wl.Listener,
    primary_selection_source_destroy: wl.Listener,
    drag_source_destroy: wl.Listener,

    events: extern struct {
        pointer_grab_begin: wl.Signal,
        pointer_grab_end: wl.Signal,

        keyboard_grab_begin: wl.Signal,
        keyboard_grab_end: wl.Signal,

        touch_grab_begin: wl.Signal,
        touch_grab_end: wl.Signal,

        request_set_cursor: wl.Signal, // event.RequestSetCursor

        request_set_selection: wl.Signal, // event.RequestSetSelection
        set_selection: wl.Signal,

        request_set_primary_selection: wl.Signal, // event.RequestSetPrimarySelection
        set_primary_selection: wl.Signal,

        request_start_drag: wl.Signal, // event.RequestStartDrag
        start_drag: wl.Signal,

        destroy: wl.Signal,
    },

    data: ?*c_void,

    extern fn wlr_seat_create(server: *wl.Server, name: [*:0]const u8) ?*Seat;
    pub const create = wlr_seat_create;

    extern fn wlr_seat_destroy(seat: *Seat) void;
    pub const destroy = wlr_seat_destroy;

    extern fn wlr_seat_client_for_wl_client(seat: *Seat, wl_client: *wl.Client) ?*Seat.Client;
    pub const clientForWlClient = wlr_seat_client_for_wl_client;

    extern fn wlr_seat_set_capabilities(seat: *Seat, capabilities: u32) void;
    pub const setCapabilities = wlr_seat_set_capabilities;

    extern fn wlr_seat_set_name(seat: *Seat, name: [*:0]const u8) void;
    pub const setName = wlr_seat_set_name;

    extern fn wlr_seat_pointer_surface_has_focus(seat: *Seat, surface: *wlr.Surface) bool;
    pub const pointerSurfaceHasFocus = wlr_seat_pointer_surface_has_focus;

    extern fn wlr_seat_pointer_enter(seat: *Seat, surface: ?*wlr.Surface, sx: f64, sy: f64) void;
    pub const pointerEnter = wlr_seat_pointer_enter;

    extern fn wlr_seat_pointer_clear_focus(seat: *Seat) void;
    pub const pointerClearFocus = wlr_seat_pointer_clear_focus;

    extern fn wlr_seat_pointer_send_motion(seat: *Seat, time_msec: u32, sx: f64, sy: f64) void;
    pub const pointerSendMotion = wlr_seat_pointer_send_motion;

    extern fn wlr_seat_pointer_send_button(seat: *Seat, time_msec: u32, button: u32, state: wlr.ButtonState) u32;
    pub const pointerSendButton = wlr_seat_pointer_send_button;

    extern fn wlr_seat_pointer_send_axis(seat: *Seat, time_msec: u32, orientation: wlr.AxisOrientation, value: f64, value_discrete: i32, source: wlr.AxisSource) void;
    pub const pointerSendAxis = wlr_seat_pointer_send_axis;

    extern fn wlr_seat_pointer_send_frame(seat: *Seat) void;
    pub const pointerSendFrame = wlr_seat_pointer_send_frame;

    extern fn wlr_seat_pointer_notify_enter(seat: *Seat, surface: *wlr.Surface, sx: f64, sy: f64) void;
    pub const pointerNotifyEnter = wlr_seat_pointer_notify_enter;

    extern fn wlr_seat_pointer_notify_clear_focus(seat: *Seat) void;
    pub const pointerNotifyClearFocus = wlr_seat_pointer_notify_clear_focus;

    extern fn wlr_seat_pointer_warp(seat: *Seat, sx: f64, sy: f64) void;
    pub const pointerWarp = wlr_seat_pointer_warp;

    extern fn wlr_seat_pointer_notify_motion(seat: *Seat, time_msec: u32, sx: f64, sy: f64) void;
    pub const pointerNotifyMotion = wlr_seat_pointer_notify_motion;

    extern fn wlr_seat_pointer_notify_button(seat: *Seat, time_msec: u32, button: u32, state: wlr.ButtonState) u32;
    pub const pointerNotifyButton = wlr_seat_pointer_notify_button;

    extern fn wlr_seat_pointer_notify_axis(seat: *Seat, time_msec: u32, orientation: wlr.AxisOrientation, value: f64, value_discrete: i32, source: wlr.AxisSource) void;
    pub const pointerNotifyAxis = wlr_seat_pointer_notify_axis;

    extern fn wlr_seat_pointer_notify_frame(seat: *Seat) void;
    pub const pointerNotifyFrame = wlr_seat_pointer_notify_frame;

    extern fn wlr_seat_pointer_start_grab(seat: *Seat, grab: ?*PointerGrab) void;
    pub const pointerStartGrab = wlr_seat_pointer_start_grab;

    extern fn wlr_seat_pointer_end_grab(seat: *Seat) void;
    pub const pointerEndGrab = wlr_seat_pointer_end_grab;

    extern fn wlr_seat_pointer_has_grab(seat: *Seat) bool;
    pub const pointerHasGrab = wlr_seat_pointer_has_grab;

    extern fn wlr_seat_set_keyboard(seat: *Seat, dev: ?*wlr.InputDevice) void;
    pub const setKeyboard = wlr_seat_set_keyboard;

    extern fn wlr_seat_get_keyboard(seat: *Seat) ?*wlr.Keyboard;
    pub const getKeyboard = wlr_seat_get_keyboard;

    extern fn wlr_seat_keyboard_send_key(seat: *Seat, time_msec: u32, key: u32, state: u32) void;
    pub const keyboardSendKey = wlr_seat_keyboard_send_key;

    extern fn wlr_seat_keyboard_send_modifiers(seat: *Seat, modifiers: *wlr.Keyboard.Modifiers) void;
    pub const keyboardSendModifiers = wlr_seat_keyboard_send_modifiers;

    extern fn wlr_seat_keyboard_enter(seat: *Seat, surface: ?*wlr.Surface, keycodes: [*]u32, num_keycodes: usize, modifiers: *wlr.Keyboard.Modifiers) void;
    pub const keyboardEnter = wlr_seat_keyboard_enter;

    extern fn wlr_seat_keyboard_clear_focus(seat: *Seat) void;
    pub const keyboardClearFocus = wlr_seat_keyboard_clear_focus;

    extern fn wlr_seat_keyboard_notify_key(seat: *Seat, time_msec: u32, key: u32, state: u32) void;
    pub const keyboardNotifyKey = wlr_seat_keyboard_notify_key;

    extern fn wlr_seat_keyboard_notify_modifiers(seat: *Seat, modifiers: *wlr.Keyboard.Modifiers) void;
    pub const keyboardNotifyModifiers = wlr_seat_keyboard_notify_modifiers;

    extern fn wlr_seat_keyboard_notify_enter(seat: *Seat, surface: *wlr.Surface, keycodes: [*]u32, num_keycodes: usize, modifiers: *wlr.Keyboard.Modifiers) void;
    pub const keyboardNotifyEnter = wlr_seat_keyboard_notify_enter;

    extern fn wlr_seat_keyboard_notify_clear_focus(seat: *Seat) void;
    pub const keyboardNotifyClearFocus = wlr_seat_keyboard_notify_clear_focus;

    extern fn wlr_seat_keyboard_start_grab(seat: *Seat, grab: *KeyboardGrab) void;
    pub const keyboardStartGrab = wlr_seat_keyboard_start_grab;

    extern fn wlr_seat_keyboard_end_grab(seat: *Seat) void;
    pub const keyboardEndGrab = wlr_seat_keyboard_end_grab;

    extern fn wlr_seat_keyboard_has_grab(seat: *Seat) bool;
    pub const keyboardHasGrab = wlr_seat_keyboard_has_grab;

    extern fn wlr_seat_touch_get_point(seat: *Seat, touch_id: i32) ?*TouchPoint;
    pub const touchGetPoint = wlr_seat_touch_get_point;

    extern fn wlr_seat_touch_point_focus(seat: *Seat, surface: *wlr.Surface, time_msec: u32, touch_id: i32, sx: f64, sy: f64) void;
    pub const touchPointFocus = wlr_seat_touch_point_focus;

    extern fn wlr_seat_touch_point_clear_focus(seat: *Seat, time_msec: u32, touch_id: i32) void;
    pub const touchPointClearFocus = wlr_seat_touch_point_clear_focus;

    extern fn wlr_seat_touch_send_down(seat: *Seat, surface: *wlr.Surface, time_msec: u32, touch_id: i32, sx: f64, sy: f64) u32;
    pub const touchSendDown = wlr_seat_touch_send_down;

    extern fn wlr_seat_touch_send_up(seat: *Seat, time_msec: u32, touch_id: i32) void;
    pub const touchSendUp = wlr_seat_touch_send_up;

    extern fn wlr_seat_touch_send_motion(seat: *Seat, time_msec: u32, touch_id: i32, sx: f64, sy: f64) void;
    pub const touchSendMotion = wlr_seat_touch_send_motion;

    extern fn wlr_seat_touch_notify_down(seat: *Seat, surface: *wlr.Surface, time_msec: u32, touch_id: i32, sx: f64, sy: f64) u32;
    pub const touchNotifyDown = wlr_seat_touch_notify_down;

    extern fn wlr_seat_touch_notify_up(seat: *Seat, time_msec: u32, touch_id: i32) void;
    pub const touchNotifyUp = wlr_seat_touch_notify_up;

    extern fn wlr_seat_touch_notify_motion(seat: *Seat, time_msec: u32, touch_id: i32, sx: f64, sy: f64) void;
    pub const touchNotifyMotion = wlr_seat_touch_notify_motion;

    extern fn wlr_seat_touch_num_points(seat: *Seat) c_int;
    pub const touchNumPoints = wlr_seat_touch_num_points;

    extern fn wlr_seat_touch_start_grab(seat: *Seat, grab: *TouchGrab) void;
    pub const touchStartGrab = wlr_seat_touch_start_grab;

    extern fn wlr_seat_touch_end_grab(seat: *Seat) void;
    pub const touchEndGrab = wlr_seat_touch_end_grab;

    extern fn wlr_seat_touch_has_grab(seat: *Seat) bool;
    pub const touchHasGrab = wlr_seat_touch_has_grab;

    extern fn wlr_seat_validate_grab_serial(seat: *Seat, serial: u32) bool;
    pub const validateGrabSerial = wlr_seat_validate_grab_serial;

    extern fn wlr_seat_validate_pointer_grab_serial(seat: *Seat, origin: ?*wlr.Surface, serial: u32) bool;
    pub const validatePointerGrabSerial = wlr_seat_validate_pointer_grab_serial;

    extern fn wlr_seat_validate_touch_grab_serial(seat: *Seat, origin: ?*wlr.Surface, serial: u32, point_ptr: *?*TouchPoint) bool;
    pub const validateTouchGrabSerial = wlr_seat_validate_touch_grab_serial;
};
