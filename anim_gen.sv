`timescale 1 ns / 1 ns // timescale for following modules

///////////////////////////////////////////////////////////////////////////////////
// // Engineer: Oguz Kaan Agac & Bora Ecer
// Create Date: 13/12/2016
// // Modified by: Abdul Rafay, Ali Imran
// Modified Date: 23/11/2023
// Design Name: Animation Logic
// Module Name: anim_gen
// Original Project Name: BASPONG
// Modified Project Name: FoosballStars
// Target Devices: BASYS3
// Description: 
// Controller for the FoosballStars
// Dependencies: 
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module anim_gen (
   clk, // basic clock
   reset, // to reset game
   x_control, // input for x coordinate
   stop_ball, // input to indicate if ball is stopped at center or moving
   right1_btn_u, // btn for first right bar to move up
   right1_btn_d, // btn for first right bar to move down
   right2_btn_d, // btn for second right bar to move up
   right2_btn_u, // btn for second right bar to move down
   left1_btn_u, // btn for first left bar to move up
   left1_btn_d, // btn for first left bar to move down
   y_control, // input for y coordinate
   video_on, // input to tell we're in safe zone to draw
   rgb, // output for vga display
   score1, // output for score on seven segment display
   score2); // output for score on seven segment display
 
input clk; 
input reset; 
input[9:0] x_control; 
input stop_ball; 
input right1_btn_u; 
input right1_btn_d; 
input left1_btn_u; 
input left1_btn_d;
input right2_btn_d;
input right2_btn_u; 
input[9:0] y_control; 
input video_on; 
output[2:0] rgb; 
output score1; 
output score2; 

reg[2:0] rgb; 
reg score1; 
reg score2; 
reg scoreChecker1; 
reg scoreChecker2; 
reg scorer; 
reg scorerNext; 

// leftbar1
integer leftbar1_t; // the distance between bar and top of the screen 
integer leftbar1_t_next; // the distance between bar and top of the screen
parameter leftbar1_l = 5; // the distance between bar and left side of screen
parameter leftbar1_thickness = 10; // thickness of the bar
parameter leftbar1_w = 100; // width of the left bar1
parameter leftbar1_v = 10; //velocity of the bar.
wire display_leftbar1; //to send left bar1 to vga
wire[2:0] rgb_leftbar1; //color 

// rightbar1
integer rightbar1_t;  // the distance between bar and top side of screen
integer rightbar1_t_next; // the distance between bar and top side of screen
parameter rightbar1_l = 625; // the distance between bar and left side of screen
parameter rightbar1_thickness = 10; //thickness of the bar
parameter rightbar1_w = 100; // width of the right bar1
parameter rightbar1_v = 10; //velocity of the bar
wire display_rightbar1; //to send right bar1 to vga
wire[2:0] rgb_rightbar1; //color

// rightbar 2 is divided in two parts, upper and lower
// both controlled with a single btn, via right2_btn_u and right2_btn_d respectively

// they also share same left placement, thickness, width, velocity and color
parameter rightbar2_l = 500; // the distance between bar and left side of screen
parameter rightbar2_thickness = 10; // thickness of the bar
parameter rightbar2_w = 60; // width of the right2 bar
parameter rightbar2_v = 7; //velocity of the bar.
wire[2:0] rgb_rightbar2; //color 

// only differ in the top bars and displays

// rightbar2_up, upper part
integer rightbar2_up_t; // the distance between bar and top of the screen 
integer rightbar2_up_t_next; // the distance between bar and top of the screen
wire display_rightbar2_up; //to send right2 bar to vga

// rightmidbar2_lw, lower part
integer rightbar2_lw_t; // the distance between bar and top of the screen 
integer rightbar2_lw_t_next; // the distance between bar and top of the screen
wire display_rightbar2_lw; //to send right2 bar to vga

// ball
integer ball_c_l; // the distance between the ball and left side of the screen
integer ball_c_l_next; // the distance between the ball and left side of the screen 
integer ball_c_t; // the distance between the ball and top side of the screen
integer ball_c_t_next; // the distance between the ball and top side of the screen
parameter ball_default_c_t = 300; // default value of the distance between the ball and left side of the screen
parameter ball_default_c_l = 300; // default value of the distance between the ball and left side of the screen
parameter ball_r = 8; //radius of the ball.
parameter horizontal_velocity = 3; // Horizontal velocity of the ball  
parameter vertical_velocity = 3; //Vertical velocity of the ball
wire display_ball; //to send ball to vga 
wire[2:0] rgb_ball;//color 

// Note: vertical velocity indicates moving right (if +ve)
//       horizontal velocity indicates moving down (if +ve)
// Therefore: -> : +ve, <- : -ve, V : +ve, ^ : -ve

// refresh
integer refresh_reg; 
integer refresh_next; 
parameter refresh_constant = 830000;  
wire refresh_rate; 

// ball animation
integer horizontal_velocity_reg; 
integer horizontal_velocity_next; 
integer vertical_velocity_reg; 

// x,y pixel cursor
integer vertical_velocity_next; 
wire[9:0] x; 
wire[8:0] y; 

// wall registers
wire display_goal;

// mux to display
wire[5:0] output_mux; 

// buffer
reg[2:0] rgb_reg; 

// x,y pixel cursor
wire[2:0] rgb_next; 

initial
    begin
    vertical_velocity_next = 0;
    vertical_velocity_reg = 0;
    horizontal_velocity_reg = 0;
    ball_c_t_next = 300;
    ball_c_t = 300;
    ball_c_l_next = 300;  
    ball_c_l = 300; 
    rightbar1_t_next = 260;
    rightbar1_t = 260;
    leftbar1_t_next = 260;
    leftbar1_t = 260;
    rightbar2_up_t_next = 220;
    rightbar2_up_t = 220;
    rightbar2_lw_t_next = 340;
    rightbar2_lw_t = 340;
   end
assign x = x_control; 
assign y = y_control; 

// refreshing

always @(posedge clk)
   begin //: process_1
   refresh_reg <= refresh_next;   
   end

//assigning refresh logics.
assign refresh_next = refresh_reg === refresh_constant ? 0 : 
	refresh_reg + 1; 
assign refresh_rate = refresh_reg === 0 ? 1'b 1 : 
	1'b 0; 

// register part
always @(posedge clk or posedge reset)
   begin 
   if (reset === 1'b 1) // to reset the game.
      begin
      ball_c_l <= ball_default_c_l;   
      ball_c_t <= ball_default_c_t;   
      rightbar1_t <= 260;   
      leftbar1_t <= 260;   
      rightbar2_up_t <= 220;   
      rightbar2_lw_t <= 340;   
      horizontal_velocity_reg <= 0;   
      vertical_velocity_reg <= 0;   
      end
   else 
      begin
      horizontal_velocity_reg <= horizontal_velocity_next; //assigns horizontal velocity
      vertical_velocity_reg <= vertical_velocity_next; // assigns vertical velocity
      if (stop_ball === 1'b 1) // throw the ball
         begin
         if (scorer === 1'b 0) // if scorer is not the 1st player throw the ball to 1st player (2nd player scored) .
            begin
            horizontal_velocity_reg <= 4;   
            vertical_velocity_reg <= 3;   
            end
         else // first player scored. Throw the ball to the 2nd player.
            begin
            horizontal_velocity_reg <= -4;   
            vertical_velocity_reg <= -3;   
            end
         end
      ball_c_l <= ball_c_l_next; //assigns the next value of the ball's location from the left side of the screen to it's location.
      ball_c_t <= ball_c_t_next; //assigns the next value of the ball's location from the top side of the screen to it's location.  
      rightbar1_t <= rightbar1_t_next;   //assigns the next value of the right bar1s's location from the top side of the screen to it's location.
      leftbar1_t <= leftbar1_t_next;   //assigns the next value of the left bar1s's location from the top side of the screen to it's location.
      rightbar2_up_t <= rightbar2_up_t_next;   //assigns the next value of the upper right bars's location from the top side of the screen to it's location.
      rightbar2_lw_t <= rightbar2_lw_t_next;   //assigns the next value of the lower right bars's location from the top side of the screen to it's location.
      scorer <= scorerNext;
      end
   end

// rightbar1 animation
always @(rightbar1_t or refresh_rate or right1_btn_d or right1_btn_u)
   begin 
   rightbar1_t_next <= rightbar1_t;//assign rightbar1_l to it's next value   
   if (refresh_rate === 1'b 1) //refresh_rate's posedge 
      begin
      if (right1_btn_u === 1'b 1 & rightbar1_t > rightbar1_v) //up btn is pressed and right bar1 can move to the left.
         begin                                                   // in other words, bar is not on the left edge of the screen.
         rightbar1_t_next <= rightbar1_t - rightbar1_v; // move rightbar1 to the left   
         end
      else if (right1_btn_d === 1'b 1 & rightbar1_t < 479 - rightbar1_v - rightbar1_w ) //down btn is pressed and right bar1 can move to the right 
         begin                                                                             //in other words, bar is not on the right edge of the screen
         rightbar1_t_next <= rightbar1_t + rightbar1_v;   //move rightbar1 to the right.
         end
      else
         begin
         rightbar1_t_next <= rightbar1_t;   
         end
      end
   end

// rightbar2 animation
always @(rightbar2_up_t or rightbar2_lw_t or refresh_rate or right2_btn_d or right2_btn_u)
   begin 
   rightbar2_up_t_next <= rightbar2_up_t;//assign rightbar2_up_t to it's next value   
   rightbar2_lw_t_next <= rightbar2_lw_t;//assign rightbar2_lw_t to it's next value   
   if (refresh_rate === 1'b 1) //refresh_rate's posedge 
      begin
      // used upper bar's top for upper bound check
      if (right2_btn_u === 1'b 1 & rightbar2_up_t > rightbar2_v) //up btn is pressed and right bar2 can move to up.
         begin                                                   // in other words, bar is not on top edge of the screen.
         rightbar2_up_t_next <= rightbar2_up_t - rightbar2_v; // move upper rightbar2 to up   
         rightbar2_lw_t_next <= rightbar2_lw_t - rightbar2_v; // move lower rightbar2 to up   
         end
      // used lower bar's top for lower bound check
      else if (right2_btn_d === 1'b 1 & rightbar2_lw_t < 479 - rightbar2_v - rightbar2_w ) //down btn is pressed and right bar2 can move down 
         begin                                                                             //in other words, bar is not on down edge of the screen
         rightbar2_up_t_next <= rightbar2_up_t + rightbar2_v;   //move upper rightbar2 down.
         rightbar2_lw_t_next <= rightbar2_lw_t + rightbar2_v;   //move lower rightbar2 down.
         end
      else
         begin
         rightbar2_up_t_next <= rightbar2_up_t;   
         rightbar2_lw_t_next <= rightbar2_lw_t;   
         end
      end
   end

// leftbar1 animation
always @(leftbar1_l or refresh_rate or left1_btn_d or left1_btn_u)
   begin 
   leftbar1_t_next <= leftbar1_t;   //assign leftbar1_l to it's next value
   if (refresh_rate === 1'b 1)  //refresh_rate's posedge
      begin
      if (left1_btn_u === 1'b 1 & leftbar1_t > leftbar1_v)//up btn is pressed and left bar1 can move to the left.
          begin                                        // in other words, bar is not on the left edge of the screen.
         leftbar1_t_next <= leftbar1_t - leftbar1_v;   //move left bar1 to the left
         end
      else if (left1_btn_d === 1'b 1 & leftbar1_t < 479 - leftbar1_v - leftbar1_w ) //down btn is pressed and right bar1 can move to the right 
        begin                                                                  //in other words, bar is not on the right edge of the screen
         leftbar1_t_next <= leftbar1_t + leftbar1_v;   // move left bar1 to the right
         end
      else
         begin
         leftbar1_t_next <= leftbar1_t;   
         end
      end
   end

// ball animation
always @(refresh_rate or ball_c_l or ball_c_t or horizontal_velocity_reg or vertical_velocity_reg)
   begin 
   ball_c_l_next <= ball_c_l;   
   ball_c_t_next <= ball_c_t;   
   scorerNext <= scorer;   
   horizontal_velocity_next <= horizontal_velocity_reg;   
   vertical_velocity_next <= vertical_velocity_reg;   
   scoreChecker1 <= 1'b 0; //1st player did not scored, default value
   scoreChecker2 <= 1'b 0; //2st player did not scored, default value  
   if (refresh_rate === 1'b 1) // posedge of refresh_rate
      begin
      // if ball hits the right bar1
      if (ball_c_t >= rightbar1_t & ball_c_t <= rightbar1_t + rightbar1_w & ball_c_l >= rightbar1_l - 3 & ball_c_l <= rightbar1_l + 5) 
         begin
         // set the direction of horizontal velocity negative
         horizontal_velocity_next <= -horizontal_velocity; 
         end
         
      // if ball hits upper right bar2
      else if (ball_c_t >= rightbar2_up_t & ball_c_t <= rightbar2_up_t + rightbar2_w & ball_c_l >= rightbar2_l - 3 & ball_c_l <= rightbar2_l + 5)
         begin
         // set the direction of horizontal velocity negative, -1 to increase speed
         horizontal_velocity_next <= -horizontal_velocity - 1; 
         end

      // if ball hits lower right bar2
      else if (ball_c_t >= rightbar2_lw_t & ball_c_t <= rightbar2_lw_t + rightbar2_w & ball_c_l >= rightbar2_l - 3 & ball_c_l <= rightbar2_l + 5)
         begin
         // set the direction of horizontal velocity negative, -1 to increase speed
         horizontal_velocity_next <= -horizontal_velocity - 1; 
         end
      
      // if ball hits upper right bar2 from back
      else if (ball_c_t >= rightbar2_up_t & ball_c_t <= rightbar2_up_t + rightbar2_w & ball_c_l >= rightbar2_l + rightbar2_thickness - 3 & ball_c_l <= rightbar2_l + rightbar2_thickness + 5)
         begin
         // set the direction of horizontal velocity negative, -1 to increase speed
         horizontal_velocity_next <= horizontal_velocity - 1; 
         end

      // if ball hits lower right bar2 from back
      else if (ball_c_t >= rightbar2_lw_t & ball_c_t <= rightbar2_lw_t + rightbar2_w & ball_c_l >= rightbar2_l + rightbar2_thickness - 3 & ball_c_l <= rightbar2_l + rightbar2_thickness + 5)
         begin
         // set the direction of horizontal velocity negative, -1 to increase speed
         horizontal_velocity_next <= horizontal_velocity - 1; 
         end
      
      // if ball hits the left bar1 
      else if (ball_c_t >= leftbar1_t & ball_c_t <= leftbar1_t + leftbar1_w & ball_c_l >= leftbar1_l + 7 & ball_c_l <= leftbar1_l + 12 ) 
         begin
         //set the direction of horizontal velocity positive  
         horizontal_velocity_next <= horizontal_velocity; 
         end
      
      // if the ball hits the top side of the screen
      if (ball_c_t < 20) 
         begin
         //set the direction of vert velocity positive
         vertical_velocity_next <= vertical_velocity; 
         end
      // if the ball hits the bottom side of the screen
      else if (ball_c_t > 460 ) 
         begin
         //set the direction of vert velocity negative.
         vertical_velocity_next <= -vertical_velocity; 
         end
      // ball hits right borders
      else if ((ball_c_l >= 630) & (ball_c_t < 200 | ball_c_t > 280)) 
        begin
        horizontal_velocity_next <= -horizontal_velocity;
        end
      // ball hits left borders
      else if ((ball_c_l <= 3) & (ball_c_t < 200 | ball_c_t > 280)) 
        begin
        horizontal_velocity_next <= horizontal_velocity;
        end 
      
      ball_c_l_next <= ball_c_l + horizontal_velocity_reg; //move the ball's horizontal location   
      ball_c_t_next <= ball_c_t + vertical_velocity_reg; // move the ball's vertical location.
      
      // if player 1 scores, in other words, ball passes through the vertical location of right bar1.
      if (ball_c_l >= 637 & ball_c_t >= 140 & ball_c_t <= 440) 
         begin
         ball_c_l_next <= ball_default_c_l;  //reset the ball's location to its default.  
         ball_c_t_next <= ball_default_c_t;  //reset the ball's location to its default.
         horizontal_velocity_next <= 0; //stop the ball.  
         vertical_velocity_next <= 0; //stop the ball
         scorerNext <= 1'b 0;   
         scoreChecker1 <= 1'b 1; //1st player scored.  
         end
      else
         begin
         scoreChecker1 <= 1'b 0;   
         end
      if (ball_c_l <= 3  & ball_c_t >= 140 & ball_c_t <= 440)// if player 2 scores, in other words, ball passes through the vertical location of left bar1.
         begin
         ball_c_l_next <= ball_default_c_l; //reset the ball's location to its default.   
         ball_c_t_next <= ball_default_c_t; //reset the ball's location to its default.  
         horizontal_velocity_next <= 0; //stop the ball  
         vertical_velocity_next <= 0; //stop the ball  
         scorerNext <= 1'b 1;   
         scoreChecker2 <= 1'b 1;  // player 2 scored  
         end
      else
         begin
         scoreChecker2 <= 1'b 0;   
         end
      end
   end

// display rightbar1 object on the screen
assign display_rightbar1 = y > rightbar1_t & y < rightbar1_t + rightbar1_w & x > rightbar1_l & 
    x < rightbar1_l + rightbar1_thickness ? 1'b 1 : 
	1'b 0; 
assign rgb_rightbar1 = 3'b 100; //color of right bar1: blue

// display upper rightbar2 object on the screen
assign display_rightbar2_up = y > rightbar2_up_t & y < rightbar2_up_t + rightbar2_w & x > rightbar2_l & 
    x < rightbar2_l + rightbar2_thickness ? 1'b 1 : 
	1'b 0; 
// display lower rightbar2 object on the screen
assign display_rightbar2_lw = y > rightbar2_lw_t & y < rightbar2_lw_t + rightbar2_w & x > rightbar2_l & 
    x < rightbar2_l + rightbar2_thickness ? 1'b 1 : 
	1'b 0; 
assign rgb_rightbar2 = 3'b 110; //color of right bar1: yellow

wire display_right2;

// checks if either part of the rightbar2 is being displayed 
assign display_right2 = display_rightbar2_lw | display_rightbar2_up;

// display leftbar1 object on the screen
assign display_leftbar1 = y > leftbar1_t & y < leftbar1_t + leftbar1_w & x > leftbar1_l &
    x < leftbar1_l + leftbar1_thickness ? 1'b 1 : 
	1'b 0; 
assign rgb_leftbar1 = 3'b 001; // color of left bar1: red


// display goal on the screen
assign display_goal = (y<5 | y>474) | ((y>0 & (y<140 | y>440) & (x<5 | x>634))) ? 1'b 1 : 1'b 0;

// display ball object on the screen
assign display_ball = (x - ball_c_l) * (x - ball_c_l) + (y - ball_c_t) * (y - ball_c_t) <= ball_r * ball_r ? 
    1'b 1 : 
	1'b 0; 
assign rgb_ball = 3'b 111; //color of ball: white

always @(posedge clk)
   begin 
   rgb_reg <= rgb_next;   
   end

// mux
assign output_mux = {video_on, display_goal, display_leftbar1, display_rightbar1, display_right2, display_ball}; 

//assign rgb_next wrt output_mux.
assign rgb_next = output_mux === 6'b 100000 ? 3'b 010 : 
	output_mux === 6'b 110000 ? 3'b 111 : 
	output_mux === 6'b 101000 ? rgb_leftbar1 : 
	output_mux === 6'b 100100 ? rgb_rightbar1 : 
	output_mux === 6'b 100010 ? rgb_rightbar2 :  
	output_mux === 6'b 100001 ? rgb_ball :
	3'b 000;        

// output part
assign rgb = rgb_reg; 
assign score1 = scoreChecker1; 
assign score2 = scoreChecker2; 

endmodule // end of module anim_gen