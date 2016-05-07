STDOUT.sync = true # DO NOT REMOVE
# Auto-generated code below aims at helping you parse
# the standard input according to the problem statement.


blocks = []


class Cell
   attr_accessor :color, :chkFlg, :x, :y, :delFlg
   def initialize(x,y,color)
       @chkFlg = false
       @delFlg = false
       @x = x
       @y = y
       @color = color
   end
end

grid = Array.new(14){Array.new(8,Cell.new(-1,-1,-2))}

def show(board)
    board.each do |line|
        line.each do |cell|
            STDERR.printf "%3d" % cell.color
        end
        STDERR.puts
    end
end

def check(board,x,y,own_color,count = 1)
    STDERR.puts "#{count}"
    board[y][x].chkFlg = true
    
    neighbor = []
    [-1,1].each do |i|
        if (x+i).between?(1,6)
#            STDERR.puts "x:#{x+i}"
            neighbor << board[y][(x+i)]
        end
        if (y+i).between?(1,12)
            neighbor << board[(y+i)][x]
        end
    end
    
#    STDERR.puts neighbor.inspect

    neighbor.each do |cell|
#        STDERR.puts "cell:#{cell.x},#{cell.y},#{cell.color},own:#{own_color}"
        if cell.color == own_color && cell.chkFlg == false
            return check(board,cell.x,cell.y,cell.color,count+1)
        else
            return count
        end
    end
    
    return count    # => 4以上なら消える
end

def put(board,x,y,color,rot,height)
    @board_c = Marshal.load(Marshal.dump(board))
    case rot
        when 0  # => . 1 2
            if @board_c[y][x+1].color == -1
                @board_c[y][x].color = color[:a]
                y = 12 - height[x]
                @board_c[y][x+1].color = color[:b]
            else
                STDERR.puts "board[#{y},#{x+1}]:#{@board_c[y][x+1].color}"
                return -1
            end
        when 1
            if @board_c[y-1][x].color == -1
                @board_c[y-1][x].color = color[:b]
                @board_c[y][x].color = color[:a]
            else
                STDERR.puts "board[#{y-1},#{x}]:#{@board_c[y-1][x].color}"
                return -1
            end
        when 2  # =>2 1 .
            if @board_c[y][x-1].color == -1
                @board_c[y][x].color = color[:a]
                y = 12 - height[x-2]
                @board_c[y][x-1].color = color[:b]
            else
                STDERR.puts "board[#{y},#{x-1}]:#{@board_c[y][x-1].color}"
                return -1
            end
        when 3
            if @board_c[y-1][x].color == -1
                @board_c[y-1][x].color = color[:a]
                @board_c[y][x].color = color[:b]
            else
                STDERR.puts "board[#{y-1},#{x}]:#{@board_c[y-1][x].color}"
                return -1
            end
    end
        
#    show @board_c
    return @board_c
end

class Simulator
    @blocks = []
    @grid = Array.new(14){Array.new(8,Cell.new(-1,-1,-2))}

    def initialize(grid,blocks)
        @grid = grid
        
        @blocks = blocks
        @height = []
        @grid.transpose.each do |line|
            @height << line.count{|item| item.color >= 0}
        end
        @height.shift
        @height.pop
        
    end
    
    # =>6箇所置く
    # =>次の盤面をシミュレート
    
    # =>タイムアウトしたら　...　各色の盤上の色との距離がそれぞれ最小になる位置に置くとか
    
    def simulate
        show @grid
        STDERR.puts @height
#        STDERR.puts @grid[1][1].chkFlg
#        STDERR.puts @grid,put(@grid,1,12,@blocks[0][:no])

        if @blocks.empty?
            return 0
        end
        
        maxc = 0
        nxt = @blocks.shift
        rnd = [[0,0],[0,1],[0,3]]
        4.times do |i|
            4.times do |j|
                rnd << [i+1,j]
            end
        end
        rnd += [[5,1],[5,2],[5,3]]
        
        sav = rnd.sample

        STDERR.puts "sav1#{sav[1]}"

        6.times do |i|
            x = i+1
            y = 12-@height[i]
                4.times do |rot|
#                    STDERR.puts "rot:#{rot},x:#{x},y:#{y},grid[y][x+1]:#{@grid[y][x+1].color},grid[y][x-1]:#{@grid[y][x-1].color}"
#                    if (rot == 0 && @grid[y][x+1].color != -1) || (rot == 2 && @grid[y][x-1].color != -1)
#                        next
#                    end

                    board = put(@grid,x,y,nxt,rot,@height)
                    if board == -1
                        next
                    end

                    # =>探索基準位置tx,ty
                    tx = [x,x]
                    ty = [y,y]
                    # 回転
                    case rot
                        when 0
                            tx[1] += 1
                            ty[1] = 12 - @height[x]
                        when 1
                            ty[1] -= 1
                        when 2
                            tx[1] -= 1
                            ty[1] = 12 - @height[x-1]
                        when 3
                            ty[0] -= 1
                    end

                    [:a,:b].each_with_index do |color,index|
                        count = checkCount(board,tx[index],ty[index],nxt[color])
                        STDERR.puts "rot:#{rot},count:#{count},x:#{tx},y:#{ty},color:#{color}"
                        
                        # =>del
                        if count >= 4
                            checkDel(board,tx[index],ty[index],nxt[color])
                        end
                        
                    # =>次の盤面(Simulate)を回して7回(最大)まで回してコンボも計算して評価
                    # =>4つ以上つながる所があればそこに置いちゃう
                        if count > maxc
                            maxc = count
                            sav = [i,rot]
                        end
                    end
                    
                    # =>next
                    
                end
#            STDERR.puts "count:#{checkCount(put(@grid,x,y,nxt),x,y,nxt)}"
        end
        
        return sav
    end
    
    def checkDel(board,x,y,color)
        # =>検査
        
        if checkCount(board,x,y,color) >= 4
            checkDel(board,x,y,color)
        end
        
        return board
    end
    
    def checkCount(board,x,y,color,count=1)
        if board == -1
            return 0
        end
        board[y][x].chkFlg = true
    
        neighbor = []
        [-1,1].each do |i|
            if (x+i).between?(1,6)
                neighbor << board[y][(x+i)]
            end
            if (y+i).between?(1,12)
                neighbor << board[(y+i)][x]
            end
        end
    
        neighbor.each do |cell|
#        STDERR.puts "cell:#{cell.x},#{cell.y},#{cell.color},own:#{color}"
            if cell.color == color && cell.chkFlg == false
                count += checkCount(board,cell.x,cell.y,color)
            end
        end
    
        return count    # => 4以上なら消える
    end
end

# game loop
loop do
    
    rot = [1,3].sample(1)
    
    
    n = 0
    row = []
    blocks = []
#    if blocks.empty?
        8.times do
        # color_a: color of the first block
        # color_b: color of the attached block
            color_a, color_b = gets.split(" ").collect {|x| x.to_i}
            blocks << {:a => color_a, :b => color_b}
#    blocks.map{|h| h[:co] = blocks.count{|hs| hs[:no] == h[:no]}}
#    blocks.sort!{|a,b| a[:co] <=> b[:co]}
        end
#    else
#        8.times do
#            color_a, color_b = gets.split(" ").collect {|x| x.to_i}
#        end
#    end
    

#    b = blocks[0]
    nxt = blocks[0]#.shift[:no]
    
    height = Array.new(6,0)
    
    12.times do |i|
        row << gets.chomp
#        STDERR.puts "row:#{row}"
        
        # 各列の高さ
        row[i].chars.each_with_index do |ch,index|
            if ch != '.'
                grid[i+1][index+1] = Cell.new(index+1,i+1,ch.to_i)
#                    STDERR.puts "#{index+1},#{i+1}:#{grid[i+1][index+1].inspect}"
                height[index]+=1
            else
                grid[i+1][index+1] = Cell.new(index+1,i+1,-1)
            end
        end
    end
    
        
    simulated = [nxt[:a],[*0,2].sample]
    sim = Simulator.new(grid,blocks)
    simulated = sim.simulate
    
    while height[simulated[0]] > 11
        simulated = [[*0..5].sample,[*0..4].sample]
    end        
    

    
    if simulated[0] >= 0
        output = "#{simulated[0]} #{simulated[1]}\n"
    else
        output = "#{((nxt[:a])%6)} 1\n"
    end

#    show grid
#    STDERR.puts "1,1:#{grid[2][2].inspect}"

    h = []
#    6.times do |i|
#        h << check(grid,i+1,11-height[i]+1,nxt)
#    end
    
#    STDERR.puts "h:#{h}"
    
    # =>連鎖組むトコの2つ上までに置けるならばそちらを優先するように。
    # =>
    target = nxt[:a]
    
#    STDERR.puts height
#    STDERR.puts target
    
#    STDERR.puts grid[12-height[target-1]][target].color,grid[12-height[target-1]-1][target].color,grid[12-height[target-1]+1][target].color

=begin

    
    if height[target-1] > height[target]
        nxt = target
    # =>    隣の1個上とそのもう1個上と置きたいトコの下にブロックがあるか
    elsif ((grid[12-height[target-1]][target].color == -1 || grid[12-height[target-1]-1][target].color == -1) && grid[12-height[target-1]+1][target].color >= 0)
        nxt = target - 1
    elsif h.max >= 3
        nxt = h.index(h.max)
    else

    row.reverse!
    col = nxt
    
#    6.times do |i|
#        if row[i*2+1][col-i] != '.' # => [1,4] [3,3] []
#            nxt -= 1
#            STDERR.puts row[i*2+1], col-i
#        else
            # => 置ける
#            break
#        end
#    end
    
    if nxt == 0
        nxt = 5
    end

    # =>左下1,0のブロックと落ちてくるやつが同じ場合、右側に4段以上積まれていたら発火
#    STDERR.puts b[:no],row[0][1]
    cnt = 0
        if blocks[0][:no] == row[0][1] || blocks[0][:no] == row[1][1]
            4.times do |i|
                5.times do |j|
                    if row[i][5-j] == '.'
                        cnt+=1
                    end
                end
            end
            if cnt == 0
                nxt = 0
            end
        end
    end

=end

    # =>相手のフィールド
    12.times do
        row = gets.chomp # One line of the map ('.' = empty, '0' = skull block, '1' to '5' = colored block)
    end
    
    
    # Write an action using puts
    # To debug: STDERR.puts "Debug messages..."
#    STDERR.puts b, nxt


 
 printf(output)   
#   printf("#{((nxt[:a])%6)} 1\n") # "x": the column in which to drop your blocks 
#   printf("#{nxt}\n") # "x": the column in which to drop your blocks 

end

