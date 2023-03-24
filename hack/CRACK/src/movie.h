#ifndef MOVIE_H
#define MOVIE_H

//================================================================================================================================
// CONST
//================================================================================================================================

const int      WND_X_SIZE =  1000;
const int      WND_Y_SIZE =   600;

const double MARIO_X_SIZE =  80.0;
const double MARIO_Y_SIZE = 140.0;

const char *FILE_MUSIC    = "../data/8_bit_music.ogg";
const char *FILE_FONT     = "../data/8_bit_font.ttf" ;
const char *FILE_GAME     = "../data/8_bit_game.jpg" ;
const char *FILE_MARIO    = "../data/mario.png";

const double          g =  9.8; // ускорение свободного падения
const double USER_SPEED =  5.0; // скорость движения по горизонтали
const double USER_JUMP  = 10.0; // скорость сразу после прыжка

//================================================================================================================================
// physiscs
//================================================================================================================================

struct physics
{
    double  x,  y;
    double vx, vy;
    double ax, ay;

    double x_size;
    double y_size;
};

#define $x      (physics_body). x
#define $vx     (physics_body).vx
#define $ax     (physics_body).ax

#define $y      (physics_body). y
#define $vy     (physics_body).vy
#define $ay     (physics_body).ay

#define $x_size (physics_body).x_size
#define $y_size (physics_body).y_size

bool physics_ctor       (physics *const body, const double x_size,
                                              const double y_size,  const double  x = 0, const double  y = 0,
                                                                    const double vx = 0, const double vy = 0,
                                                                    const double ax = 0, const double ay = 0);

bool physics_set_param  (physics *const body,                       const double  x = 0, const double  y = 0,
                                                                    const double vx = 0, const double vy = 0,
                                                                    const double ax = 0, const double ay = 0);
bool physics_simple_move(physics *const body);

//================================================================================================================================
// mario
//================================================================================================================================

enum MOVE_DIRECTION
{
    MOVE_LEFT   ,
    MOVE_RIGHT  ,
};

//--------------------------------------------------------------------------------------------------------------------------------

struct mario_world
{
    int x_min, x_max;
    int y_max;

    physics        kinematic;
    MOVE_DIRECTION direction;
};

#define $x_min      (mario_world_character).x_min
#define $x_max      (mario_world_character).x_max
#define $y_max      (mario_world_character).y_max

#define $kinematic  (mario_world_character).kinematic
#define $direction  (mario_world_character).direction

bool mario_world_ctor               (mario_world *const mario_life);
bool mario_world_simple_move        (mario_world *const mario_life, sf::Sprite *const mario_sprite);
bool mario_world_reculc_acceleration(mario_world *const mario_life);

bool mario_world_go_left (mario_world *const mario_life);
bool mario_world_go_right(mario_world *const mario_life);
bool mario_world_jump    (mario_world *const mario_life);
bool mario_world_stop    (mario_world *const mario_life);

//--------------------------------------------------------------------------------------------------------------------------------

struct mario_handler
{
    sf::Texture mario_tex;
    sf::Sprite  mario_spr;
    mario_world mario_life;
};

#define $mario_tex  (mario_handler_exemplar).mario_tex
#define $mario_spr  (mario_handler_exemplar).mario_spr
#define $mario_life (mario_handler_exemplar).mario_life

bool mario_handler_ctor(mario_handler *const mario);

//================================================================================================================================
// render_text
//================================================================================================================================

struct render_text
{
    sf::Font message_font;
    sf::Text message_text;
};

#define $msg_font (render_text_str).message_font
#define $msg_text (render_text_str).message_text

bool render_text_ctor       (render_text *const str, const char *const     message,
                                                     const unsigned character_size,
                                                     const double x_pos,
                                                     const double y_pos);

bool render_text_set_message (render_text *const str,   const char *const message);
bool render_text_progress_bar(render_text *const str, sf::RenderWindow *const wnd);

//================================================================================================================================
// render_back
//================================================================================================================================

struct render_back
{
    sf::Texture back_texture;
    sf::Sprite  back_sprite;
};

//================================================================================================================================
// crack_video
//================================================================================================================================

struct crack_video
{
    sf::Music     music;
    render_text   rnd_text;
    render_back   rnd_back;
    mario_handler hero;
};

#endif //MOVIE_H