
                        sBG = "d30_2083.s+windowsP256.s+Tile.0007_c.s+tile-floor2_c.s+tomatoes256.s+text.ext+square-lattice.s+d30_2083.s+d30_2199.s+D101_s.s+darkoak_texture.gif+Bark.0003_s.ext+campbell256.s+college-inn256.s+d30_2076.s+rice_bg.jpg+rough_bg.gif+pcd3614-24.s+feynman-cr.s+red-peppers256.s+redcarpet.gif";
		bgDir = "textures/";
		
		aBG = sBG.split("+");
		
		iBG = Math.floor(Math.random()*aBG.length);
		document.body.background = bgDir + aBG[iBG];