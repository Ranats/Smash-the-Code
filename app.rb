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
#                STDERR.puts "board[#{y},#{x+1}]:#{@board_c[y][x+1].color}"
                return -1
            end
        when 1
            if @board_c[y-1][x].color == -1
                @board_c[y-1][x].color = color[:b]
                @board_c[y][x].color = color[:a]
            else
#                STDERR.puts "board[#{y-1},#{x}]:#{@board_c[y-1][x].color}"
                return -1
            end
        when 2  # =>2 1 .
            if @board_c[y][x-1].color == -1
                @board_c[y][x].color = color[:a]
                y = 12 - height[x-2]
                @board_c[y][x-1].color = color[:b]
            else
#                STDERR.puts "board[#{y},#{x-1}]:#{@board_c[y][x-1].color}"
                return -1
            end
        when 3
            if @board_c[y-1][x].color == -1
                @board_c[y-1][x].color = color[:a]
                @board_c[y][x].color = color[:b]
            else
#                STDERR.puts "board[#{y-1},#{x}]:#{@board_c[y-1][x].color}"
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
    end
    
    # =>6箇所置く
    # =>次の盤面をシミュレート
    
    # =>タイムアウトしたら　...　各色の盤上の色との距離がそれぞれ最小になる位置に置くとか
    
    def search(grid,height,nxt,maxc,sav)
        # =>このループをメソッドとして外に出して呼び出す。スコアを返す
        6.times do |i|
            x = i+1
            y = 12-height[i]
                4.times do |rot|
                    # =>ディープコピーしてるので置くたびに新しい盤面のオブジェクトを生成
                    board_p = put(grid,x,y,nxt,rot,height)
                    if board_p == -1
                        next
                    end

                    # =>探索基準位置tx,ty
                    tx = [x,x]
                    ty = [y,y]
                    # 回転
                    case rot
                        when 0
                            tx[1] += 1
                            ty[1] = 12 - height[x]
                        when 1
                            ty[1] -= 1
                        when 2
                            tx[1] -= 1
                            ty[1] = 12 - height[x-1]
                        when 3
                            ty[0] -= 1
                    end

                    [:a,:b].each_with_index do |color,index|
                        board = board_p
                        count = checkCount(board,tx[index],ty[index],nxt[color])
#                        STDERR.puts "rot:#{rot},count:#{count},x:#{tx},y:#{ty},color:#{color}"
                        
                        # =>del
                        if count >= 4
                            # =>消すのと同時に連鎖数の判定
#                            STDERR.puts "rensa:#{checkDel(board,tx[index],ty[index],nxt[color])}"
                            # =>連鎖数じゃなくて消した数
                            count += checkDel(board,tx[index],ty[index],nxt[color],count)
                        end
                        
                    # =>次の盤面(Simulate)を回して7回(最大)まで回してコンボも計算して評価
                    # =>4つ以上つながる所があればそこに置いちゃう
                        if count > maxc
                            maxc = count
                            sav = [i,rot]
                        end
                    end
                    
                    # =>next
                    # =>1パターン置いた時の盤面　board_p
                    # =>コレを次のシミュレータに渡して回す?
                    
                end
#            STDERR.puts "count:#{checkCount(put(@grid,x,y,nxt),x,y,nxt)}"
        end
        
        return sav
        
    end
    
    def height_map(grid)
        height = []
        grid.transpose.each do |line|
            height << line.count{|item| item.color >= 0}
        end
        height.shift
        height.pop
        return height
    end
    
    def start
        @height = []
        @grid.transpose.each do |line|
            @height << line.count{|item| item.color >= 0}
        end
        @height.shift
        @height.pop
        retarr = simulate(@grid,@blocks,@height)
        STDERR.puts retarr.inspect
        return retarr[1]
    end
    
    $count = 0
    def simulate(grid,blocks,height,maxc = [0,[0,0]],maxo=0)
#        show grid
        STDERR.puts blocks.size
#        STDERR.puts @grid[1][1].chkFlg
#        STDERR.puts @grid,put(@grid,1,12,@blocks[0][:no])

        if blocks.size < 8
            return maxc
        end
        
        maxco = 0
        nxt = blocks.shift
#        rnd = [[0,0],[0,1],[0,3]]
#        4.times do |i|
#            4.times do |j|
#                rnd << [i+1,j]
#            end
#        end
#        rnd += [[5,1],[5,2],[5,3]]
        
        sav = []
        
#        sav = search(@grid,@height,nxt,maxc,sav)

        # =>このループをメソッドとして外に出して呼び出す。スコアを返す
        6.times do |i|
            x = i+1
            y = 12-height[i]
            max4 = Array.new(4,0)
                4.times do |rot|
                    # =>ディープコピーしてるので置くたびに新しい盤面のオブジェクトを生成
                    board_p = put(grid,x,y,nxt,rot,height)
                    if board_p == -1
                        next
                    end

                    # =>探索基準位置tx,ty
                    tx = [x,x]
                    ty = [y,y]
                    # 回転
                    case rot
                        when 0
                            tx[1] += 1
                            ty[1] = 12 - height[x]
                        when 1
                            ty[1] -= 1
                        when 2
                            tx[1] -= 1
                            ty[1] = 12 - height[x-1]
                        when 3
                            ty[0] -= 1
                    end

                    count = [0,0]
                    
                    board = board_p
                    count = [checkCount(board,tx[0],ty[0],nxt[:a]),
                            checkCount(board,tx[1],ty[1],nxt[:b])]
                    if count.sort!.reverse![0] >= 4
                        [:a,:b].each_with_index do |color,index|
#                        STDERR.puts "rot:#{rot},count:#{count},x:#{tx},y:#{ty},color:#{color}"
                        
                        # =>del
                            # =>消すのと同時に連鎖数の判定
#                            STDERR.puts "rensa:#{checkDel(board,tx[index],ty[index],nxt[color])}"
                            # =>連鎖数じゃなくて消した数
                            count[0] += checkDel(board,tx[index],ty[index],count[0])
                        end
                        
                    # =>次の盤面(Simulate)を回して7回(最大)まで回してコンボも計算して評価
                    # =>4つ以上つながる所があればそこに置いちゃう
#                        if count[0] > maxc[0]
#                            maxc = count[0]
#                            sav = [i,rot]
#                        end
                    end
                        max4[rot] = [count[0],[i,rot]]
                    
                    # =>next
                    # =>1パターン置いた時の盤面　board_p
                    # =>コレを次のシミュレータに渡して回す?
                    
                    retarr = simulate(board_p,blocks,height_map(board_p),max4.max_by{|m| m[0]},maxo)
                    maxo = retarr[0]
                    
                    if retarr[0] > maxco
                        maxco = retarr[0]
                        sav << retarr[1]
                    end
                    STDERR.puts "sav:#{sav}"
                end
#            STDERR.puts "count:#{checkCount(put(@grid,x,y,nxt),x,y,nxt)}"
        end
#        return 
        return [maxco,sav]
    end
    
    def checkDel(board,x,y,rensa = 1,total)
        STDERR.puts "del:rensa #{rensa}"
        t = []
        # =>検査
        board.map do |line|
            line.map do |cell|
                if cell.chkFlg
                    cell.color = -1
                    t << [cell.x,cell.y]
                    
#                    STDERR.puts "cell.x/y #{cell.x},#{cell.y}"
#                    STDERR.puts board[cell.y][cell.x+1]
#                    STDERR.puts board[cell.y][cell.x-1]
                    
                    
                    # =>ゼロも一緒に消す
                    [-1,1].each do |i|
                        if (cell.x+i).between?(1,6)
                            if board[cell.y][(cell.x+i)].color == 0
                                board[cell.y][(cell.x+i)].color = -1
                                t << [cell.x+i,cell.y]
                            end
                        end
                        if (cell.y+i).between?(1,12)
                            if board[(cell.y+i)][cell.x].color == 0
                                board[(cell.y+i)][cell.x].color = -1
                                t << [cell.x,(cell.y+i)]
                            end
                        end
                    end
                end
                cell.chkFlg  = false
            end
        end
        
        STDERR.puts "t:#{t}"
        
        # 落とす
        board_rotate = board.transpose
        board_rotate.each_with_index do |line,x|
            field = line[1,12]
            field.delete_if{|x| x.color == -1 }
            remain_size = field.size
            y = 1
            while field.size < 12
                field.unshift(Cell.new(x+1,12-field.size,-1))
                y+=1
            end
            line[1,12] = field
            line.each_with_index do |cell,i|
                cell.x = x
                cell.y = i
#                STDERR.puts "#{x}:#{cell.x},#{cell.y}"
            end
        end
        
        board = board_rotate.transpose
        
#        show board
#        STDERR.puts "t:#{t}"
        
        # => ここまではOK
        t.each do |cell|
#            STDERR.puts "cell:#{cell}"
#            STDERR.puts "color:#{board[cell[1]][cell[0]].color}"
#            STDERR.puts "checkFlg:#{board[cell[1]][cell[0]].chkFlg}"
            # =>消したセルの座標(高さ)を記録しておいてループで回してその座標でカウントチェック?
            if board[cell[1]][cell[0]].color > 0 && board[cell[1]][cell[0]].chkFlg == false 
                count = checkCount(board,cell[0],cell[1],board[cell[1]][cell[0]].color)
                STDERR.puts "count:#{count}"
                if count >= 4
                    # =>連鎖数
#                    rensa += checkDel(board,cell[0],cell[1],board[cell[1]][cell[0]].color)
                    # =>消えたトータルの数
                    total += checkDel(board,cell[0],cell[1],1,total+count)
                end
            end
        end
        
        return total
    end
    
    def checkCount(board,x,y,color,count=1)
        if board == -1
            return 0
        end

#        STDERR.puts "x,y:#{x},#{y}"

        board[y][x].chkFlg = true
    
        neighbor = []
        [-1,1].each do |pm|
            if (x+pm).between?(1,6)
                neighbor << board[y][(x+pm)]
            end
            if (y+pm).between?(1,12)
                neighbor << board[(y+pm)][x]
            end
        end
        
#        neighbor.each do |cell|
#            STDERR.puts "cell:#{cell.x},#{cell.y}"
#        end
        
        neighbor.each do |cell|
#        STDERR.puts "cell:#{cell.x},#{cell.y},#{cell.color},own:#{color}"
            if cell.color == color && cell.chkFlg == false
                count += checkCount(board,cell.x,cell.y,color)
            end
        end
        
        return count    # => 4以上なら消える
    end
end


    $simulated = []

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
    
            STDERR.puts "go"

    STDERR.puts $simulated
    
    if $simulated.empty?
        sim = Simulator.new(grid,blocks)
        $simulated = sim.start
    end
    
        STDERR.puts "go2"

#    while height[simulated[0][0]] > 11
#        simulated = [[*0..5].sample,[*0..4].sample]
#    end        
    

    sft = $simulated.shift.flatten
    output = "#{sft[0]} #{sft[1]}"
#    if simulated[0] >= 0
#        output = "#{simulated[0]} #{simulated[1]}\n"
#    else
#        output = "#{((nxt[:a])%6)} 1\n"
#    end

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
     STDERR.puts "end"

#   printf("#{((nxt[:a])%6)} 1\n") # "x": the column in which to drop your blocks 
#   printf("#{nxt}\n") # "x": the column in which to drop your blocks 

end
