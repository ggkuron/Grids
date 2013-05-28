module cell.collection;

import cell.cell;
import cell.rangecell;
import util.direct;
import util.array;
import util.range;
import cell.flex_common;
debug(collec) import std.stdio;
debug(cell) import std.stdio;

// 自由変形できる構造
class Collection : CellStructure{
private:

    Cell[] box;
    // _min_row 等に依存
    // rangeとは独立している
    Cell[LR][UpDown] _edge;

    int _numof_row = 1;  // 
    int _numof_col = 1;
    
    RangeCell _range;

    // _min_row 等に依存
    // rangeとは独立している
    Cell[][Direct] _edge_line;

    // Range をクロスさせた状態を表現する
    int _min_row = int.max;
    int _min_col = int.max;
    int _max_row = int.min;
    int _max_col = int.min;

    bool _fixed;
    unittest{
        auto cb = new Collection();
        cb.create_in(Cell(3,3));
        assert(cb.is_hold(Cell(3,3)));
        assert(!cb.is_hold(Cell(3,4)));
        cb.expand(Direct.right);
        assert(cb.is_hold(Cell(3,4)));
        cb = new Collection();
        cb.create_in(Cell(5,5));
        cb.expand(Direct.right);
        cb.expand(Direct.down);
        assert(cb.box.count_lined(Cell(5,5),Direct.right) == 1);
        assert(cb.box.count_lined(Cell(5,5),Direct.down) == 1);
        debug(cell) writeln("@@@@ update_info unittest start @@@@@");
        cb = new Collection();
        cb.create_in(Cell(5,5));
        assert(cb.top_left == Cell(5,5));
        assert(cb._numof_row == 1);
        assert(cb._numof_col == 1);

        cb.hold_tl(Cell(0,0),5,5);

        debug(cell) writefln("!!!! box %s",cb.box);
        assert(cb.top_left == Cell(0,0));
        assert(cb.bottom_right == Cell(4,4));
        debug(cell) writeln("_numof_row:",cb._numof_row);
        debug(cell) writeln("_numof_col:",cb._numof_col);
        assert(cb._numof_row == 5);
        assert(cb._numof_col == 5);
        debug(cell) writeln("#### update_info unittest end ####");
    }
    final void expand1(const Direct dir){
        debug(cell) writeln("@@@@ expand start @@@@");

        const Cell[] one_edges = edge_line[dir];
        _edge_line[dir].clear();
        foreach(c; one_edges) //one_edgesが配列でないとexpanded_edgeがsortされない
        {
            auto moved = c.if_moved(dir);
            box ~= moved;
            _edge_line[dir] ~= moved;
            _range.add(moved);
        }
        if(dir.is_horizontal)
        {
            _edge[up][cast(LR)dir].move(dir);
            _edge[down][cast(LR)dir].move(dir);
            _edge_line[Direct.up] ~= _edge[up][cast(LR)dir];
            _edge_line[Direct.down] ~= _edge[down][cast(LR)dir];
            ++_numof_col;
            
            if(dir.is_positive)
                ++_max_col;
            else 
                --_min_col;
        }
        else // if(dir.is_vertical)
        {
          _edge[cast(UpDown)dir][left].move(dir);
          _edge[cast(UpDown)dir][right].move(dir);
          _edge_line[Direct.left] ~= _edge[cast(UpDown)dir][left];
          _edge_line[Direct.right] ~= _edge[cast(UpDown)dir][right];

          ++_numof_row;
          if(dir.is_positive)
              ++_max_row;
          else 
              --_min_row;
        }
        _range.expand(dir);

        debug(cell) writeln("#### expand end ####");
    }
    final void remove1(const Direct dir){
        debug(cell) writeln("@@@@ Collection.remove start @@@@");

        if(dir.is_horizontal && _numof_col <= 1
        || dir.is_vertical && _numof_row <= 1 )
            return;
        auto delete_line = edge_line[dir];
        foreach(c; delete_line)
        {
           util.array.remove!(Cell)(box,c);
           debug(cell) writefln("deleted %s",c);
        }

        if(dir.is_horizontal)
        {
          _edge[up][cast(LR)dir].move(dir.reverse);
          _edge[down][cast(LR)dir].move(dir.reverse);
          --_numof_col;
          if(dir.is_positive)
              --_max_col;
          else 
              ++_min_col;
        }
        else // if(dir.is_vertical)
        {
          _edge[cast(UpDown)dir][left].move(dir.reverse);
          _edge[cast(UpDown)dir][right].move(dir.reverse);
          --_numof_row;
          if(dir.is_positive)
              --_max_row;
          else 
              ++_min_row;
        }
        _range.remove(dir);
            
        debug(cell) writeln("#### Collection.remove end ####");
        debug(move) writeln("col_table are ",col_table);
        debug(move) writeln("row_table are ",row_table);
    }
    final void move1(const Direct dir){
        // この順番でないと1Cellだけのときに失敗する
        expand(dir);
        remove(dir.reverse);
    }
public:
    this(){
        // _range = RangeCell();
    }
    this(Cell ul,int rw,int cw){
        debug(cell){ 
            writeln("ctor start");
            writefln("rw %d cw %d",rw,cw);
        }
        this();
        hold_tl(ul,rw,cw);
        debug(cell)writeln("ctor end");
    }
    // this(Collection oldone)
    //     in{
    //     assert(!oldone.get_cells().empty);
    //     }
    //     out{
    //     assert(!box.empty);
    //     }
    // body{
    //     debug(cell) writeln("take after start");
    //     box = oldone.get_cells().dup;
    //     _edge = oldone._edge.dup();
    //     _min_col = oldone.min_col;
    //     _max_col = oldone.max_col;
    //     _min_row = oldone.min_row;
    //     _max_row = oldone.max_row;
    //     _range = oldone._range.clone();

    //     oldone.clear();
    //     debug(cell) writeln("end");
    // }

    void create_in(const Cell c){
        clear(); // <- range.clear()
        box ~= c;
        _range.add(c);
        _min_row = _max_row = c.row;
        _min_col = _max_col = c.column;
        _edge[up][left] = c;
        _edge[up][right] = c;
        _edge[down][left] = c;
        _edge[down][right] = c;
        _edge_line[Direct.left] ~= c;
        _edge_line[Direct.right] ~= c;
        _edge_line[Direct.up] ~= c;
        _edge_line[Direct.down] ~= c;
    }
    // 任意のタイミングで行う操作
    void add(const Cell c)
        in{
        assert(!box.empty);
        }
        out{
        assert(is_box(box));
        }
    body{ // create initial box
        bool min_row_f,min_col_f,max_row_f,max_col_f;
        box ~= c;

        if(c.row < _range.row)
        {
            min_row_f = true;
            _edge_line[Direct.up].clear();
            _edge_line[Direct.up] ~= c;
        }
        else if(c.row > _range.row)
        {
            max_row_f = true;
            _edge_line[Direct.down].clear();
            _edge_line[Direct.down] ~= c;
        }
        else if(c.row == _range.row)
            _edge_line[Direct.up] ~= c;
        else // if(c.row == row_table.max)
            _edge_line[Direct.down] ~= c;

        if(c.column < _range.col)
        {
            min_row_f = true;
            _edge_line[Direct.left].clear();
            _edge_line[Direct.left] ~= c;
        }
        else if(c.column > _range.col)
        {
            max_col_f = true;
            _edge_line[Direct.right].clear();
            _edge_line[Direct.right] ~= c;
        }
        else if(c.column == _range.col)
            _edge_line[Direct.left] ~= c;
        else // if(c.column == col_table.max)
            _edge_line[Direct.right] ~= c;

        // cellを判定後に更新
        _range.add(c);

        if(max_col_f && max_row_f)
            _edge[down][right] = c;
        if(max_col_f && min_row_f)
            _edge[up][right] = c;
        if(min_col_f && max_row_f)
            _edge[down][left] = c;
        if(min_col_f && min_row_f)
            _edge[up][left] = c;
    }
    void expand(in Direct dir,in int width=1){
        int w = width;
        while(w--)
            expand1(dir);
    }
    void remove(in Direct dir,in int width=1){
        int w = width;
        while(w--)
            remove1(dir);
    }
    void clear(){
        import std.stdio;
        box.clear();
        _range.clear();
        _numof_row =1;
        _numof_col =1;
        _max_row = int.min;
        _max_col = int.min;
        _min_row = int.max;
        _min_col = int.max;
        _edge.clear();
        _edge_line.clear();
    }
    // 線形探索:要素数は小さいものしか想定してないから
    // box.lenthでアルゴリズム切り分ける必要があるかも
    bool is_hold(in Cell c){
        return .is_in(box,c);
    }
    
    void move(in Cell c){
        if(!c.row)
            move(right,c.row);
        if(!c.column)
            move(down,c.column);
    }
    void move(in Direct dir,in int width=1){
        int w = width;
        while(w--)
            move1(dir);
    }
    unittest{
        debug(cell) writeln("@@@@ Collection move unittest start @@@@");
        auto cb = new Collection(Cell(5,5),5,5);
        assert(cb.top_left == Cell(5,5));
        assert(cb.bottom_right == Cell(9,9));
        assert(cb.top_right == Cell(5,9));
        assert(cb.bottom_left == Cell(9,5));
        assert(cb.min_row == 5);
        assert(cb.min_col == 5);
        assert(cb.max_row == 9);
        assert(cb.max_col == 9);
        cb.move(Direct.up);
        assert(cb.top_left == Cell(4,5));
        assert(cb.bottom_right == Cell(8,9));
        assert(cb.top_right == Cell(4,9));
        assert(cb.bottom_left == Cell(8,5));
        assert(cb.min_row == 4);
        assert(cb.min_col == 5);
        assert(cb.max_row == 8);
        assert(cb.max_col == 9);
        cb.move(Direct.left);
        assert(cb.top_left == Cell(4,4));
        assert(cb.bottom_right == Cell(8,8));
        assert(cb.top_right == Cell(4,8));
        assert(cb.bottom_left == Cell(8,4));
        assert(cb.min_row == 4);
        assert(cb.min_col == 4);
        assert(cb.max_row == 8);
        assert(cb.max_col == 8);
        cb.move(Direct.right);
        assert(cb.top_left == Cell(4,5));
        assert(cb.bottom_right == Cell(8,9));
        assert(cb.top_right == Cell(4,9));
        assert(cb.bottom_left == Cell(8,5));
        assert(cb.min_row == 4);
        assert(cb.min_col == 5);
        assert(cb.max_row == 8);
        assert(cb.max_col == 9);

        debug(cell) writeln("#### Collection move unittest end ####");
    }
    bool is_on_edge(in Cell c)const{
            
        foreach(each_edged; edge_line())
        {
            if(each_edged.is_in(c)) return true;
            else continue;
        }
        return false;
    }
    unittest{
        debug(cell) writeln("@@@@is_on_edge unittest start@@@@");
        auto cb = new Collection();
        auto c = Cell(3,3);
        cb.create_in(c);
        assert(cb.is_on_edge(c));

        foreach(idir; Direct.min .. Direct.max+1)
        {   // 最終的に各方向に1Cell分拡大
            auto dir = cast(Direct)idir;
            cb.expand(dir);
            debug(collec) writeln("edge ",cb.edge_line[dir]);
            debug(collec) writeln("tl ",cb.top_left);
            debug(collec) writeln("br ",cb.bottom_right);

            assert(cb.is_on_edge(cb.top_left));
            assert(cb.is_on_edge(cb.bottom_right));
        }
        debug(cell) writeln("####is_on_edge unittest end####");
    }
    bool is_on_edge(in Cell c,in Direct on)const{
        return edge_line[on].is_in(c);
    }
    @property const (Cell[][Direct]) edge_line()const{
        debug(cell) writefln("min_row %d max_row %d\n min_col %d max_col %d",min_row,max_row,min_col,max_col);
        return  [Direct.right:_edge_line[Direct.right],
                 Direct.left:_edge_line[Direct.left],
                 Direct.up:_edge_line[Direct.up],
                 Direct.down:_edge_line[Direct.down]];
    }
    @property bool empty()const{
        return box.empty();
    }
    // 初期段階に矩形領域を確保するために使う
    void hold_tl(in Cell start,int h,int w) // TopLeft
        in{
        assert(h >= 0);
        assert(w >= 0);
        }
        out{
        // assert(is_box(box));
        }
    body{
        clear();
        create_in(start);

        if(!w && !h) return;
        if(w)--w;
        if(h)--h;
        while(w || h)
        {
            if(w > 0)
            {
                expand(Direct.right);
                --w;
            }
            if(h > 0)
            {
                expand(Direct.down);
                --h;
            }
        }
        debug(collec) writeln("hold ",box);
    }
    void hold_br(in Cell lr,int h,int w) // BottomRight
        in{
        assert(h >= 0);
        assert(w >= 0);
        }
        out{
        assert(is_box(box));
        }
    body{
        clear();
        auto s_r = lr.row-h+1;
        if(s_r < 0) s_r = 0;
        auto s_c = lr.column-w+1;
        if(s_c < 0) s_c = 0;
        auto start = Cell(s_r,s_c);
        hold_tl(start,h,w);
    }
    unittest{
        debug(cell) writeln("@@@@hold_br unittest start@@@@");
        auto cb = new Collection();
        cb.hold_br(Cell(5,5),3,3);

        assert(cb.top_left == Cell(3,3));
        assert(cb._numof_row == 3);
        assert(cb._numof_col == 3);
        debug(cell) writeln("####hold_br unittest end####");
    }
    void hold_tr(in Cell ur,int h,int w)
        in{
        assert(h >= 0);
        assert(w >= 0);
        }
        out{
        assert(is_box(box));
        }
    body{
        clear();
        auto s_r = ur.row;
        auto s_c = ur.column-w+1;
        if(s_c<0){
            w += s_c;
            s_c = 0;
        }
        auto start = Cell(s_r,s_c);
        hold_tl(start,h,w);
    }
    unittest{
        debug(cell) writeln("@@@@ hold_tr unittest start @@@@");
        auto cb = new Collection();
        cb.hold_tr(Cell(5,5),3,3);

        assert(cb.top_left == Cell(5,3));
        assert(cb._numof_row == 3);
        assert(cb._numof_col == 3);
        debug(cell) writeln("#### hold_tr unittest start ####");
    }
    void hold_bl(in Cell ll,int h,int w)
        in{
        assert(h >= 0);
        assert(w >= 0);
        }
        out{
        assert(is_box(box));
        }
    body{
        clear();
        auto s_r = ll.row-h+1;
        if(s_r < 0) s_r = 0;
        auto s_c = ll.column;
        auto start = Cell(s_r,s_c);
        hold_tl(start,h,w);
    }
    unittest{
        debug(cell) writeln("@@@@ hold_bl unittest start @@@@");
        auto cb = new Collection();
        cb.hold_bl(Cell(5,5),3,3);

        assert(cb.top_left == Cell(3,5));
        assert(cb._numof_row == 3);
        assert(cb._numof_col == 3);
        debug(cell) writeln("#### hold_bl unittest end ####");
    }
    unittest{
        debug(cell) writeln("@@@@ hold_tl unittest start @@@@");
        auto cb = new Collection();
        cb.hold_tl(Cell(3,3),5,5);

        assert(cb.top_left == Cell(3,3));
        assert(cb.bottom_right == Cell(7,7));
        cb = new Collection();
        cb.hold_tl(Cell(3,3),0,0);
        assert(cb.top_left == Cell(3,3));
        assert(cb.bottom_right == Cell(3,3));
        debug(cell) writeln("#### hold_tl unittest end ####");
    }

    // getter:
    final:
    int numof_row()const{
        return _numof_row;
    }
    int numof_col()const{
        return _numof_col;
    }
    @property int min_row()const{
        return _min_row;
    }
    @property int max_row()const{
        return _max_row;
    }
    @property int min_col()const{
        return _min_col;
    }
    @property int max_col()const{
        return _max_col;
    }
    const(Cell)[] get_cells()const{
        return box;
    }
    @property Cell top_left()const{
        return _edge[up][left];
    }
    @property Cell bottom_right()const{
        return _edge[down][right];
    }
    @property Cell top_right()const{
        return _edge[up][right];
    }
    @property Cell bottom_left()const{
        return _edge[down][left];
    }
    Cell[] grab_box(){
        return box;
    }
}

