USE [testData]
GO
/****** Object:  Table [dbo].[tbl_test]    Script Date: 20/11/2018 20:06:37 ******/
DROP TABLE IF EXISTS [dbo].[tbl_test]
GO
/****** Object:  Table [dbo].[tbl_relation]    Script Date: 20/11/2018 20:06:37 ******/
DROP TABLE IF EXISTS [dbo].[tbl_relation]
GO
/****** Object:  Table [dbo].[tbl_category]    Script Date: 20/11/2018 20:06:37 ******/
DROP TABLE IF EXISTS [dbo].[tbl_category]
GO
/****** Object:  Table [dbo].[rel_category_in_test]    Script Date: 20/11/2018 20:06:37 ******/
DROP TABLE IF EXISTS [dbo].[rel_category_in_test]
GO
/****** Object:  Table [dbo].[rel_category_in_test]    Script Date: 20/11/2018 20:06:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[rel_category_in_test](
	[testID] [int] NULL,
	[categoryID] [int] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[tbl_category]    Script Date: 20/11/2018 20:06:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_category](
	[category_id] [int] IDENTITY(1,1) NOT NULL,
	[categoryTitle] [nvarchar](50) NULL,
	[categoryAlias] [nvarchar](50) NULL,
	[categoryValue] [nvarchar](200) NULL,
	[categoryOrderKey] [int] NULL,
 CONSTRAINT [PK_tbl_categories] PRIMARY KEY CLUSTERED 
(
	[category_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[tbl_relation]    Script Date: 20/11/2018 20:06:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_relation](
	[relation_id] [int] IDENTITY(1,1) NOT NULL,
	[relationName] [nvarchar](50) NULL,
	[relationBody] [nvarchar](max) NULL,
 CONSTRAINT [PK_tbl_relation] PRIMARY KEY CLUSTERED 
(
	[relation_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[tbl_test]    Script Date: 20/11/2018 20:06:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_test](
	[test_id] [int] IDENTITY(1,1) NOT NULL,
	[name] [nvarchar](50) NULL,
	[bool] [bit] NULL,
	[startDate] [datetime] NULL,
	[notes] [nvarchar](max) NULL,
	[relationID] [int] NULL,
	[dec] [decimal](10,2) NULL,
 CONSTRAINT [PK_tbl_test] PRIMARY KEY CLUSTERED 
(
	[test_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
INSERT [dbo].[rel_category_in_test] ([testID], [categoryID]) VALUES (1, 1)
GO
INSERT [dbo].[rel_category_in_test] ([testID], [categoryID]) VALUES (1, 2)
GO
INSERT [dbo].[rel_category_in_test] ([testID], [categoryID]) VALUES (1, 4)
GO
SET IDENTITY_INSERT [dbo].[tbl_category] ON 
GO
INSERT [dbo].[tbl_category] ([category_id], [categoryTitle], [categoryAlias], [categoryValue], [categoryOrderKey]) VALUES (1, N'Cat 1', N'cat1', N'1', 0)
GO
INSERT [dbo].[tbl_category] ([category_id], [categoryTitle], [categoryAlias], [categoryValue], [categoryOrderKey]) VALUES (2, N'Cat 2', N'cat2', N'2', 1)
GO
INSERT [dbo].[tbl_category] ([category_id], [categoryTitle], [categoryAlias], [categoryValue], [categoryOrderKey]) VALUES (3, N'Cat 3', N'cat3', N'3', 2)
GO
INSERT [dbo].[tbl_category] ([category_id], [categoryTitle], [categoryAlias], [categoryValue], [categoryOrderKey]) VALUES (4, N'Another Category', N'another', N'more', 3)
GO
SET IDENTITY_INSERT [dbo].[tbl_category] OFF
GO
SET IDENTITY_INSERT [dbo].[tbl_relation] ON 
GO
INSERT [dbo].[tbl_relation] ([relation_id], [relationName], [relationBody]) VALUES (1, N'Snigga', NULL)
GO
INSERT [dbo].[tbl_relation] ([relation_id], [relationName], [relationBody]) VALUES (2, N'Digga', NULL)
GO
INSERT [dbo].[tbl_relation] ([relation_id], [relationName], [relationBody]) VALUES (3, N'Wagga', NULL)
GO
INSERT [dbo].[tbl_relation] ([relation_id], [relationName], [relationBody]) VALUES (4, N'Chugga', NULL)
GO
SET IDENTITY_INSERT [dbo].[tbl_relation] OFF
GO
SET IDENTITY_INSERT [dbo].[tbl_test] ON 
GO
INSERT [dbo].[tbl_test] ([test_id], [name], [bool], [startDate], [notes], [relationID]) VALUES (1, N'Dave Wagga', 1, CAST(N'2018-11-10T17:06:34.360' AS DateTime), NULL, NULL)
GO
INSERT [dbo].[tbl_test] ([test_id], [name], [bool], [startDate], [notes], [relationID]) VALUES (2, N'Waggag', 0, CAST(N'2018-10-29T21:07:35.093' AS DateTime), NULL, 2)
GO
INSERT [dbo].[tbl_test] ([test_id], [name], [bool], [startDate], [notes], [relationID]) VALUES (3, N'Jimmy Jenkins', 1, CAST(N'2018-10-29T21:07:35.093' AS DateTime), NULL, 1)
GO
INSERT [dbo].[tbl_test] ([test_id], [name], [bool], [startDate], [notes], [relationID]) VALUES (4, N'Sam Smith', 1, CAST(N'2018-10-29T21:07:35.093' AS DateTime), NULL, 4)
GO
SET IDENTITY_INSERT [dbo].[tbl_test] OFF
GO
