-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------
local network = require("network")
local json = require( "json" )

display.setDefault( "anchorX", 0 )

local zRotationCorrected = 0

local data_point_cache = {}
local data_point_flush = {}

local angular_velocity_xaxis = 0.0
local angular_velocity_yaxis = 0.0
local angular_velocity_zaxis = 0.0

local acceleration_xaxis = 0.0
local acceleration_yaxis = 0.0
local acceleration_zaxis = 0.0

local angle_xaxis = 0.0
local angle_yaxis = 0.0
local angle_zaxis = 0.0

local time_delta = 0.0

local xGravityLabel = display.newText( "xGravity:", 10, 15, native.systemFontBold, 12 )
local yGravityLabel = display.newText( "yGravity:", 10, 31, native.systemFontBold, 12 )
local zGravityLabel = display.newText( "zGravity:", 10, 47, native.systemFontBold, 12 )
local timeDeltaLabel = display.newText( "time delta:", 10, 63, native.systemFontBold, 12 )

local xGravityText = display.newText( "", 80, 15, native.systemFont, 12 )
local yGravityText = display.newText( "", 80, 31, native.systemFont, 12 )
local zGravityText = display.newText( "", 80, 47, native.systemFont, 12 )
local timeDeltaText = display.newText( "", 80, 63, native.systemFont, 12 )

local function round( f, n )
	p = math.pow( 10, n ) * 1.0
	return math.floor( f * p ) / p
end

local function onTilt( event )
	acceleration_xaxis = event.xGravity -- positive right, negative left
	acceleration_yaxis = event.yGravity -- positive up, negative down
	acceleration_zaxis = event.zGravity

	time_delta = event.deltaTime

    xGravityText.text = acceleration_xaxis
    yGravityText.text = acceleration_yaxis
    zGravityText.text = acceleration_zaxis
	timeDeltaText.text = time_delta

	local data_point = {}
	data_point['device_name']				= 'humeapp'
	data_point['device_id']					= 'test1'
	data_point['logged_at']					= os.date( "%Y-%m-%dT%H:%M:%SZ%Z" )
	data_point['time_delta']				= time_delta
	-- data_point['date']						= nil
	-- data_point['time']						= nil
	data_point['acceleration_xaxis']		= acceleration_xaxis
	data_point['acceleration_yaxis']		= acceleration_yaxis
	data_point['acceleration_zaxis']		= acceleration_zaxis
	data_point['angular_velocity_xaxis']	= angular_velocity_xaxis
	data_point['angular_velocity_yaxis']	= angular_velocity_yaxis
	data_point['angular_velocity_zaxis']	= angular_velocity_zaxis
	-- data_point['angle_xaxis']				= angle_xaxis
	-- data_point['angle_yaxis']				= angle_yaxis
	-- data_point['angle_zaxis']				= angle_zaxis

	table.insert(data_point_cache, data_point)

	if table.getn(data_point_cache) > 300 then

		data_point_flush = data_point_cache
		data_point_cache = {}

		sendRequest( data_point_flush )

	end

    return true
end


-- Called when a new gyroscope measurement has been received
local function onGyroscopeDataReceived( event )
    -- Calculate approximate rotation traveled via delta time
    -- Remember that rotation rate is in radians per second
    -- local deltaRadians = event.yRotation * event.deltaTime
    -- local deltaDegrees = deltaRadians * (180/math.pi)

	angular_velocity_xaxis = event.xRotation
	angular_velocity_yaxis = event.yRotation
	angular_velocity_zaxis = event.zRotation

	deltaTimeRotation = event.deltaTime

end

local function networkListener( event )

    if ( event.isError ) then
        print( "Network error: ", event.response )
    else
        print ( "RESPONSE: " .. event.response )
    end
end

function sendRequest( payload_table )
	local path = "https://hume-bridge.herokuapp.com/data"
	local payload = json.encode( payload_table )

	local headers = {}
	headers["Content-Type"] = "application/json"

	local params = {}
	params.headers = headers
	params.body = payload

	network.request( path, "POST", networkListener, params )

end

system.setGyroscopeInterval( 100 )
system.setAccelerometerInterval( 100 )

Runtime:addEventListener( "accelerometer", onTilt )
Runtime:addEventListener( "gyroscope", onGyroscopeDataReceived )
