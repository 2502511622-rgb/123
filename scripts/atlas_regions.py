"""Measure alpha-separated atlas cells without modifying source image pixels."""
from PIL import Image

def grid_regions(path,columns,rows):
    image=Image.open(path).convert('RGBA');alpha=image.getchannel('A');width,height=image.size
    ys=[0]
    for row in range(1,rows):
        center=round(height*row/rows);span=round(height/rows*.2)
        def cost(y):return sum(v>100 for v in alpha.crop((0,y,width,y+1)).get_flattened_data())*100+abs(y-center)
        ys.append(min(range(max(1,center-span),min(height,center+span+1)),key=cost))
    ys.append(height);regions=[]
    for row in range(rows):
        xs=[0]
        for col in range(1,columns):
            center=round(width*col/columns);span=round(width/columns*.24)
            def cost(x):return sum(v>100 for v in alpha.crop((x,ys[row],x+1,ys[row+1])).get_flattened_data())*100+abs(x-center)
            xs.append(min(range(max(1,center-span),min(width,center+span+1)),key=cost))
        xs.append(width)
        for col in range(columns):
            used=alpha.crop((xs[col],ys[row],xs[col+1],ys[row+1])).point(lambda v:255 if v>40 else 0).getbbox()
            assert used,(path,row,col)
            left,top,right,bottom=used
            regions.append([left+xs[col],top+ys[row],right-left,bottom-top])
    return regions
