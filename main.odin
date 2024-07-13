package breakout
import "core:fmt"
import "core:math"
import "core:math/linalg"
import rl "vendor:raylib"

WINDOW_HEIGHT :: 640
WINDOW_WIDTH :: 640
DRAW_SIZE :: WINDOW_HEIGHT / 2
PADDLE_WIDTH :: 50
PADDLE_HEIGHT :: 6
INITIAL_PADDLE_POS_Y :: 260
PADDLE_SPEED :: 200
BALL_SPEED :: 260
BALL_RADIUS :: 4
BALL_START_Y :: 160

paddle_pos: rl.Vector2
ball_pos: rl.Vector2
ball_dir: rl.Vector2
camera: rl.Camera2D
started := false

restart :: proc() {
	x: f32 = DRAW_SIZE / 2 - PADDLE_WIDTH / 2
	paddle_pos = rl.Vector2{x, INITIAL_PADDLE_POS_Y}
	ball_pos = rl.Vector2{DRAW_SIZE / 2, BALL_START_Y}
	started = false
}

main :: proc() {
	fmt.println("hello world")
	rl.SetConfigFlags({.VSYNC_HINT})
	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Breakout!")
	rl.SetTargetFPS(60)
	// game related code
	restart()
	camera = rl.Camera2D {
		zoom = f32(rl.GetScreenHeight() / DRAW_SIZE),
	}

	for !rl.WindowShouldClose() {
		dt: f32
		if !started {
			ball_pos = {
				DRAW_SIZE / 2 + f32(math.cos(rl.GetTime()) * DRAW_SIZE / 2.5),
				BALL_START_Y,
			}

			if rl.IsKeyPressed(.SPACE) {
				paddle_middle := rl.Vector2{paddle_pos.x + PADDLE_WIDTH / 2, paddle_pos.y}
				ball_to_paddle := paddle_middle - ball_pos
				ball_dir = linalg.normalize0(ball_to_paddle)
				started = true
			}
		} else {
			dt = rl.GetFrameTime()
		}

		previous_ball_pos := ball_pos
		ball_pos += ball_dir * BALL_SPEED * dt
		paddle_move_velocity: f32

		if rl.IsKeyDown(.LEFT) {
			paddle_move_velocity -= PADDLE_SPEED
		}
		if rl.IsKeyDown(.RIGHT) {
			paddle_move_velocity += PADDLE_SPEED
		}

		paddle_pos.x += paddle_move_velocity * dt
		paddle_pos.x = clamp(paddle_pos.x, 0, DRAW_SIZE - PADDLE_WIDTH)
		paddle_rect := rl.Rectangle{paddle_pos.x, paddle_pos.y, PADDLE_WIDTH, PADDLE_HEIGHT}

		if rl.CheckCollisionCircleRec(ball_pos, BALL_RADIUS, paddle_rect) {
			collision_normal: rl.Vector2

			if previous_ball_pos.y < paddle_rect.y + paddle_rect.height {
				collision_normal += {0, -1}
				ball_pos.y = paddle_rect.y - BALL_RADIUS
			}

			if previous_ball_pos.y > paddle_rect.y + paddle_rect.height {
				collision_normal += {0, 1}
				ball_pos.y = paddle_rect.y + paddle_rect.height + BALL_RADIUS
			}

			if previous_ball_pos.x < paddle_rect.x {
				collision_normal += {-1, 0}
			}

			if previous_ball_pos.x > paddle_rect.x + paddle_rect.width {
				collision_normal += {1, 0}
			}

			if collision_normal != 0 {
				ball_dir = linalg.normalize(
					linalg.reflect(ball_dir, linalg.normalize(collision_normal)),
				)
			}
		}

		//-- begin draw cycle ---------------------------
		rl.BeginDrawing()
		rl.BeginMode2D(camera)
		rl.ClearBackground(rl.RAYWHITE)
		rl.DrawRectangleRec(paddle_rect, rl.BLACK)
		rl.DrawCircleV(ball_pos, BALL_RADIUS, rl.ORANGE)
		rl.EndMode2D()
		rl.EndDrawing()
		// ---------------------------------------------
	}
	rl.CloseWindow()
}
