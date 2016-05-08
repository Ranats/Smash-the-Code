STDOUT.sync = true # DO NOT REMOVE
# Auto-generated code below aims at helping you parse
# the standard input according to the problem statement.

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

#grid = Array.new(14){Array.new(8,Cell.new(-1,-1,-2))}
grid = Array.new(12){Array.new(6,Cell.new(0,0,0))}

def show(board)
    board.each do |line|
        line.each do |cell|
            STDERR.printf "%3d" % cell.color
        end
        STDERR.puts
    end
end

$patternList = [{p:[0,0],v:0},{p:[0,1],v:0},{p:[0,3],v:0}]
4.times do |i|
    4.times do |j|
        $patternList << {p:[i+1,j],v:0}
    end
end
$patternList += [{p:[5,1],v:0},{p:[5,2],v:0},{p:[5,3],v:0}]

class Simulator2
    def initialize(grid,blocks)
        @grid = Marshal.load(Marshal.dump(grid))
        
        @blocks = Marshal.load(Marshal.dump(blocks))
        @height = []
        @grid.transpose.each do |line|
            @height << line.count{|item| item.color >= 0}
        end
        #@height.shift
        #@height.pop
        
    end
    
    def put(board, x, y, color, rot, height)
        board_after = Marshal.load(Marshal.dump(board))
#        STDERR.puts "x:#{x},y:#{y}"
#        STDERR.puts board_after[y][x].inspect
        case rot
            when 0 # => . 1 2
                if height[x+1] < 12
                    board_after[y][x].color = color[:a]
                    y = 11 - height[x+1]
                    board_after[y][x+1].color = color[:b]
                else
                    return -1
                end
            when 1
                if y >= 0
                    board_after[y-1][x].color = color[:b]
                    board_after[y][x].color = color[:a]
                else
#                STDERR.puts "board[#{y-1},#{x}]:#{@board_c[y-1][x].color}"
                    return -1
                end
            when 2 # =>2 1 .
                if height[x-1] < 12
                    board_after[y][x].color = color[:a]
                    y = 11 - height[x-1]
                    board_after[y][x-1].color = color[:b]
                else
                    return -1
                end
            when 3
                if y >= 0
                    board_after[y-1][x].color = color[:a]
                    board_after[y][x].color = color[:b]
                else
#                STDERR.puts "board[#{y-1},#{x}]:#{@board_c[y-1][x].color}"
                    return -1
                end
        end

        return board_after
    end
    
    def start
#        show @grid
#        STDERR.puts @grid.size
        return simulate
    end
    
    def simulate
        nxt = @blocks.shift
        
        $patternList.each do |pattern|
             # =>評価値のまとめ
            fp = []
            
            # =>置く
            x,y = pattern[:p][0],11-@height[pattern[:p][0]]
            board_after = put(@grid, x, y, nxt, pattern[:p][1], @height)
            if board_after == -1
                pattern[:v] = 0
                next
            end

            case pattern[:p][1]
                when 0
                    x2 = x+1
                    y2 = 11 - @height[x2]
                when 1
                    x2 = x
                    y2 = y - 1
                when 2
                    x2 = x-1
                    y2 = 11 - @height[x2]
                when 3
                    x2 = x
                    y2 = y
                    y -= 1
            end
            
            # =>連結個数を求める
            cc1 = countConnected(board_after, x, y, nxt[:a])
            cc2 = countConnected(board_after, x2, y2, nxt[:b])
            
#            STDERR.puts "pattern:#{pattern},x:#{x},y:#{y} cc1:#{cc1}, cc2:#{cc2}"
            cc = cc1 + cc2
            if cc1 > 0 && cc2 > 0
                cc += 64
            end
            
            fp << cc
            
            # =>同じ列に存在する同色個数
            sc1 = countSameCol(board_after, x, y, nxt[:a])
            sc2 = countSameCol(board_after, x2, y2, nxt[:b])
            
            sc = sc1 + sc2
            if sc1 > 0 && sc2 > 0
                sc += 24
            end
            
            fp << sc
            
            # =>隣接行の下方に存在する同色個数
            step = 0
            [[x,y,:a],[x2,y2,:b]].each do |z|
                # =>右下
                if z[0] < 5
                    step += board_r[z[0]+1].slice(z[1],11).count{|cell| cell.color == nxt[z[2]]} / 2.0 * z[1]
                end
                # =>左下
                if z[0] > 0
                    step += board_r[z[0]-1].slice(z[1],11).count{|cell| cell.color == nxt[z[2]]} / 2.0 * z[1]
                end
            end
            
            fp << step
            
            STDERR.puts fp.inspect
            
            pattern[:v] = cc
        end
        
        return $patternList.max_by{|pattern| pattern[:v]}[:p]
    end
    
    # =>自分以外をカウント
    def countConnected(board,x,y,color,count = 0)
#        STDERR.puts "x:#{x},y:#{y}"
        board[y][x].chkFlg = true
        
        neighbor = []
        [-1,1].each do |pm|
            if (x+pm).between?(0,5)
                neighbor << board[y][(x+pm)]
            end
            if (y+pm).between?(0,11)
                neighbor << board[(y+pm)][x]
            end
        end
        
#        STDERR.puts "color:#{color}"
#        neighbor.each do |cell|
#            STDERR.puts "x:#{cell.x} y:#{cell.y} color:#{cell.color}"
#        end
        
        neighbor.each do |cell|
            if !cell.chkFlg && cell.color == color
                count += countConnected(board, cell.x, cell.y, color, 1)
            end
        end
        
#        STDERR.puts "count:#{count}"
        return count
    end
    
        def countSameCol(board,x,y,color,count = 0)
        board_r = board.transpose
        return board_r[x].count{|cells| cells.color == color} -1
    end
end

# game loop
loop do
    blocks = []
#    if blocks.empty?
    8.times do
        # color_a: color of the first block
        # color_b: color of the attached block
      color_a, color_b = gets.split(" ").collect {|x| x.to_i}
      blocks << {:a => color_a, :b => color_b}
    end
    

    row = []
    nxt = blocks[0]#.shift[:no]
    
    height = Array.new(6,0)
    
    12.times do |y|
        row << gets.chomp
        
        # 各列の高さ
        row[y].chars.each_with_index do |ch,x|
            if ch != '.'
                grid[y][x] = Cell.new(x,y,ch.to_i)
                height[x]+=1
            else
                grid[y][x] = Cell.new(x,y,-1)
            end
        end
    end
    
    sim = Simulator2.new(grid,blocks)
    simulated = sim.start
    
    output = "#{simulated[0]} #{simulated[1]}\n"
    
    # =>相手のフィールド
    12.times do
        row = gets.chomp # One line of the map ('.' = empty, '0' = skull block, '1' to '5' = colored block)
    end
    
    printf(output)

end
